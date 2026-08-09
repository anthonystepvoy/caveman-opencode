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

function Remove-JsonTrailingCommas([string]$Content) {
  $result = [System.Text.StringBuilder]::new($Content.Length)
  $inString = $false
  $escaped = $false

  for ($index = 0; $index -lt $Content.Length; $index++) {
    $character = $Content[$index]

    if ($inString) {
      [void]$result.Append($character)
      if ($escaped) {
        $escaped = $false
      } elseif ($character -eq '\') {
        $escaped = $true
      } elseif ($character -eq '"') {
        $inString = $false
      }
      continue
    }

    if ($character -eq '"') {
      $inString = $true
      [void]$result.Append($character)
      continue
    }

    if ($character -eq ',') {
      $next = $index + 1
      while ($next -lt $Content.Length -and [char]::IsWhiteSpace($Content[$next])) {
        $next++
      }
      if ($next -lt $Content.Length -and ($Content[$next] -eq '}' -or $Content[$next] -eq ']')) {
        continue
      }
    }

    [void]$result.Append($character)
  }

  return $result.ToString()
}

function ConvertFrom-OpenCodeJson([string]$Content) {
  try {
    return $Content | ConvertFrom-Json
  } catch {
    $normalized = Remove-JsonTrailingCommas $Content
    if ($normalized -eq $Content) {
      throw
    }
    return $normalized | ConvertFrom-Json
  }
}

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
  $config = ConvertFrom-OpenCodeJson $content
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
