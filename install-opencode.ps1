$ErrorActionPreference = "Stop"

$scriptPath = $MyInvocation.MyCommand.Path
if ([string]::IsNullOrWhiteSpace($scriptPath)) {
  $repo = (Get-Location).Path
} else {
  $repo = Split-Path -Parent $scriptPath
}

$sourceOpenCode = Join-Path $repo ".opencode"
$tempDir = $null
$configDir = Join-Path $env:USERPROFILE ".config\opencode"
$skillsDir = Join-Path $configDir "skills"
$commandsDir = Join-Path $configDir "commands"
$configFile = Join-Path $configDir "opencode.json"
$agentsFile = Join-Path $configDir "AGENTS.caveman.md"

$skills = @(
  "caveman",
  "caveman-commit",
  "caveman-review",
  "caveman-help",
  "caveman-compress"
)

function Ensure-Property($Object, [string]$Name, $Value) {
  if ($Object.PSObject.Properties.Name -notcontains $Name) {
    $Object | Add-Member -MemberType NoteProperty -Name $Name -Value $Value
  }
}

if (-not (Test-Path -LiteralPath (Join-Path $sourceOpenCode "AGENTS.md"))) {
  $archiveUrl = $env:CAVEMAN_OPENCODE_ARCHIVE_URL
  if ([string]::IsNullOrWhiteSpace($archiveUrl)) {
    $archiveUrl = "https://github.com/anthonystepvoy/caveman-opencode/archive/refs/heads/main.zip"
  }

  $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ("caveman-opencode-" + [System.Guid]::NewGuid().ToString("N"))
  $zipPath = Join-Path $tempDir "source.zip"
  New-Item -ItemType Directory -Force $tempDir | Out-Null

  Write-Host "Downloading Caveman for OpenCode from $archiveUrl"
  Invoke-WebRequest -Uri $archiveUrl -OutFile $zipPath
  Expand-Archive -LiteralPath $zipPath -DestinationPath $tempDir -Force

  $sourceDir = Get-ChildItem -LiteralPath $tempDir -Directory | Select-Object -First 1
  if (-not $sourceDir) {
    throw "Downloaded archive did not contain a source directory."
  }

  $sourceOpenCode = Join-Path $sourceDir.FullName ".opencode"
  if (-not (Test-Path -LiteralPath (Join-Path $sourceOpenCode "AGENTS.md"))) {
    throw "Downloaded archive did not contain .opencode/AGENTS.md."
  }
}

New-Item -ItemType Directory -Force $skillsDir | Out-Null
New-Item -ItemType Directory -Force $commandsDir | Out-Null

foreach ($skill in $skills) {
  $source = Join-Path $sourceOpenCode "skills\$skill"
  $target = Join-Path $skillsDir $skill
  if (Test-Path -LiteralPath $target) {
    Remove-Item -Recurse -Force -LiteralPath $target
  }
  Copy-Item -Recurse -Force -LiteralPath $source -Destination $target
}

Copy-Item -Force (Join-Path $sourceOpenCode "commands\*.md") -Destination $commandsDir
Copy-Item -Force -LiteralPath (Join-Path $sourceOpenCode "AGENTS.md") -Destination $agentsFile

if (Test-Path -LiteralPath $configFile) {
  $config = Get-Content -LiteralPath $configFile -Raw -Encoding UTF8 | ConvertFrom-Json
} else {
  $config = [pscustomobject]@{}
}

Ensure-Property $config "instructions" @()
$instructions = @($config.instructions)
if ($instructions -notcontains $agentsFile) {
  $config.instructions = @($instructions + $agentsFile)
}

Ensure-Property $config "permission" ([pscustomobject]@{})
Ensure-Property $config.permission "skill" ([pscustomobject]@{})
foreach ($skill in $skills) {
  if ($config.permission.skill.PSObject.Properties.Name -contains $skill) {
    $config.permission.skill.$skill = "allow"
  } else {
    $config.permission.skill | Add-Member -MemberType NoteProperty -Name $skill -Value "allow"
  }
}

$config | ConvertTo-Json -Depth 50 | Set-Content -LiteralPath $configFile -Encoding UTF8

if ($tempDir -and (Test-Path -LiteralPath $tempDir)) {
  Remove-Item -Recurse -Force -LiteralPath $tempDir
}

Write-Host "Installed Caveman for OpenCode to $configDir"
Write-Host "Restart OpenCode, then use /caveman, /caveman-help, /caveman-review, /caveman-commit, or /caveman-compress."
