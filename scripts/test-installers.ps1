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

try {
  $env:USERPROFILE = $testRoot
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

  & (Join-Path $repo "install-opencode.ps1")

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
  if (Test-Path -LiteralPath $testRoot) {
    Remove-Item -Recurse -Force -LiteralPath $testRoot
  }
}
