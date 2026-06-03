$ErrorActionPreference = "Stop"

$repo = Split-Path -Parent $MyInvocation.MyCommand.Path
$sourceOpenCode = Join-Path $repo ".opencode"
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

Write-Host "Installed Caveman for OpenCode to $configDir"
Write-Host "Restart OpenCode, then use /caveman, /caveman-help, /caveman-review, /caveman-commit, or /caveman-compress."
