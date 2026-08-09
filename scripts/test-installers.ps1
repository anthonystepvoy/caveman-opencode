$ErrorActionPreference = "Stop"

function Assert-True([bool]$Condition, [string]$Message) {
  if (-not $Condition) {
    throw "Assertion failed: $Message"
  }
}

$repo = Split-Path -Parent $PSScriptRoot
$testRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("caveman-opencode-test-" + [guid]::NewGuid().ToString("N"))
$originalUserProfile = $env:USERPROFILE
$originalDefaultLevel = $env:CAVEMAN_OPENCODE_DEFAULT_LEVEL
$originalArchiveUrl = $env:CAVEMAN_OPENCODE_ARCHIVE_URL
$serverProcess = $null

try {
  $env:CAVEMAN_OPENCODE_DEFAULT_LEVEL = "ultra"

  $configDir = Join-Path $testRoot ".config\opencode"
  $configFile = Join-Path $configDir "opencode.json"
  $agentsFile = Join-Path $configDir "AGENTS.caveman.md"
  New-Item -ItemType Directory -Force -Path $configDir | Out-Null

  @'
{
  "instructions": [
    "keep.md",
  ],
  "custom": "literal,}",
  "nested": {
    "value": "literal,]",
  },
  "permission": {
    "skill": {
      "existing": "allow",
    },
  },
}
'@ | Set-Content -LiteralPath $configFile -Encoding UTF8

  Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction Stop
  $archiveRoot = Join-Path $testRoot "archive"
  $archiveSource = Join-Path $archiveRoot "caveman-opencode-main"
  $archivePath = Join-Path $testRoot "source.zip"
  New-Item -ItemType Directory -Force -Path $archiveSource | Out-Null
  Copy-Item -Recurse -Force -LiteralPath (Join-Path $repo ".opencode") -Destination $archiveSource
  [System.IO.Compression.ZipFile]::CreateFromDirectory($archiveRoot, $archivePath)

  $portProbe = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, 0)
  $portProbe.Start()
  $port = ([System.Net.IPEndPoint]$portProbe.LocalEndpoint).Port
  $portProbe.Stop()
  $serverUrl = "http://127.0.0.1:$port/source.zip"
  $serverOutputPath = Join-Path $testRoot "archive-server.out"
  $serverErrorPath = Join-Path $testRoot "archive-server.err"
  $python = (Get-Command python -ErrorAction Stop).Source
  $pythonArguments = "-m http.server $port --bind 127.0.0.1 --directory `"$testRoot`""
  $serverProcess = Start-Process -FilePath $python -ArgumentList $pythonArguments -PassThru -WindowStyle Hidden -RedirectStandardOutput $serverOutputPath -RedirectStandardError $serverErrorPath

  $remoteDir = Join-Path $testRoot "remote-installer"
  $remoteInstaller = Join-Path $remoteDir "install-opencode.ps1"
  New-Item -ItemType Directory -Force -Path $remoteDir | Out-Null
  Copy-Item -Force -LiteralPath (Join-Path $repo "install-opencode.ps1") -Destination $remoteInstaller
  $env:CAVEMAN_OPENCODE_ARCHIVE_URL = $serverUrl

  $serverDeadline = [DateTime]::UtcNow.AddSeconds(10)
  $serverReady = $false
  while (-not $serverReady -and [DateTime]::UtcNow -lt $serverDeadline) {
    if ($serverProcess.HasExited) {
      $serverDetails = Get-Content -LiteralPath $serverErrorPath -Raw -ErrorAction SilentlyContinue
      throw "Archive server exited before startup. $serverDetails"
    }
    $client = [System.Net.Sockets.TcpClient]::new()
    try {
      $client.Connect("127.0.0.1", $port)
      $serverReady = $client.Connected
    } catch {
      Start-Sleep -Milliseconds 100
    } finally {
      $client.Close()
    }
  }
  Assert-True $serverReady "archive server should start"

  $env:USERPROFILE = $testRoot
  try {
    & $remoteInstaller
  } catch {
    $serverDetails = Get-Content -LiteralPath $serverErrorPath -Raw -ErrorAction SilentlyContinue
    throw "Remote installer failed: $($_.Exception.Message). Archive server: $serverDetails"
  }

  $config = Get-Content -LiteralPath $configFile -Raw -Encoding UTF8 | ConvertFrom-Json
  $skills = @("caveman", "caveman-commit", "caveman-review", "caveman-help", "caveman-compress")

  Assert-True (@($config.instructions).Count -eq 2) "installer should preserve and append instructions"
  Assert-True (@($config.instructions) -contains "keep.md") "existing instruction should remain"
  Assert-True (@($config.instructions) -contains $agentsFile) "Caveman instruction should be added"
  Assert-True ($config.custom -eq "literal,}") "comma before a brace inside a string should remain"
  Assert-True ($config.nested.value -eq "literal,]") "comma before a bracket inside a string should remain"
  Assert-True ($config.permission.skill.existing -eq "allow") "existing skill permission should remain"
  foreach ($skill in $skills) {
    Assert-True ($config.permission.skill.$skill -eq "allow") "$skill should be allowed"
  }
  Assert-True ((Get-Content -LiteralPath $agentsFile -Raw -Encoding UTF8) -match "(?m)^Default mode: ultra\.") "default intensity should be applied"

  & (Join-Path $repo "uninstall-opencode.ps1")

  $config = Get-Content -LiteralPath $configFile -Raw -Encoding UTF8 | ConvertFrom-Json
  Assert-True (@($config.instructions).Count -eq 1) "uninstaller should remove only the Caveman instruction"
  Assert-True (@($config.instructions) -contains "keep.md") "existing instruction should survive uninstall"
  Assert-True ($config.custom -eq "literal,}") "custom string should survive uninstall"
  Assert-True ($config.nested.value -eq "literal,]") "nested string should survive uninstall"
  Assert-True ($config.permission.skill.existing -eq "allow") "existing permission should survive uninstall"
  foreach ($skill in $skills) {
    Assert-True ($config.permission.skill.PSObject.Properties.Name -notcontains $skill) "$skill permission should be removed"
  }
  Assert-True (-not (Test-Path -LiteralPath $agentsFile)) "Caveman instruction file should be removed"

  Write-Host "PowerShell installer tests passed."
} finally {
  $env:USERPROFILE = $originalUserProfile
  if ($null -eq $originalDefaultLevel) {
    Remove-Item Env:CAVEMAN_OPENCODE_DEFAULT_LEVEL -ErrorAction SilentlyContinue
  } else {
    $env:CAVEMAN_OPENCODE_DEFAULT_LEVEL = $originalDefaultLevel
  }
  if ($null -eq $originalArchiveUrl) {
    Remove-Item Env:CAVEMAN_OPENCODE_ARCHIVE_URL -ErrorAction SilentlyContinue
  } else {
    $env:CAVEMAN_OPENCODE_ARCHIVE_URL = $originalArchiveUrl
  }
  if ($null -ne $serverProcess -and -not $serverProcess.HasExited) {
    Stop-Process -Id $serverProcess.Id -Force -ErrorAction SilentlyContinue
    [void]$serverProcess.WaitForExit(5000)
  }
  if (Test-Path -LiteralPath $testRoot) {
    Remove-Item -Recurse -Force -LiteralPath $testRoot
  }
}
