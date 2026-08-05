$ErrorActionPreference = "Stop"

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

foreach ($skill in $skills) {
  $skillPath = Join-Path $skillsDir $skill
  if (Test-Path -LiteralPath $skillPath) {
    Remove-Item -Recurse -Force -LiteralPath $skillPath
  }
}

foreach ($command in @("caveman", "caveman-commit", "caveman-review", "caveman-help", "caveman-compress")) {
  $commandPath = Join-Path $commandsDir "$command.md"
  if (Test-Path -LiteralPath $commandPath) {
    Remove-Item -Force -LiteralPath $commandPath
  }
}

if (Test-Path -LiteralPath $agentsFile) {
  Remove-Item -Force -LiteralPath $agentsFile
}

if (Test-Path -LiteralPath $configFile) {
  $content = Get-Content -LiteralPath $configFile -Raw -Encoding UTF8
  try {
    $config = $content | ConvertFrom-Json
  } catch {
    $config = ($content -replace ',\s*([\]}])', '$1') | ConvertFrom-Json
  }
  if ($config.PSObject.Properties.Name -contains "instructions") {
    $config.instructions = @(@($config.instructions) | Where-Object { $_ -ne $agentsFile })
  }
  if (
    $config.PSObject.Properties.Name -contains "permission" -and
    $config.permission.PSObject.Properties.Name -contains "skill"
  ) {
    foreach ($skill in $skills) {
      if ($config.permission.skill.PSObject.Properties.Name -contains $skill) {
        $config.permission.skill.PSObject.Properties.Remove($skill)
      }
    }
  }
  $config | ConvertTo-Json -Depth 50 | Set-Content -LiteralPath $configFile -Encoding UTF8
}

Write-Host "Removed Caveman OpenCode files from $configDir"
