#!/usr/bin/env sh
set -eu

config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
skills_dir="$config_dir/skills"
commands_dir="$config_dir/commands"
config_file="$config_dir/opencode.json"
agents_file="$config_dir/AGENTS.caveman.md"
skills="caveman caveman-commit caveman-review caveman-help caveman-compress"

for skill in $skills; do
  rm -rf "$skills_dir/$skill"
done

for command in caveman caveman-commit caveman-review caveman-help caveman-compress; do
  rm -f "$commands_dir/$command.md"
done

rm -f "$agents_file"

if [ -f "$config_file" ]; then
  node - "$config_file" "$agents_file" <<'NODE'
const fs = require("fs")

const [configFile, agentsFile] = process.argv.slice(2)
const skills = ["caveman", "caveman-commit", "caveman-review", "caveman-help", "caveman-compress"]

function stripTrailingCommas(content) {
  let result = ""
  let inString = false
  let escaped = false

  for (let index = 0; index < content.length; index += 1) {
    const character = content[index]

    if (inString) {
      result += character
      if (escaped) {
        escaped = false
      } else if (character === "\\") {
        escaped = true
      } else if (character === '"') {
        inString = false
      }
      continue
    }

    if (character === '"') {
      inString = true
      result += character
      continue
    }

    if (character === ",") {
      let next = index + 1
      while (next < content.length && /\s/.test(content[next])) {
        next += 1
      }
      if (content[next] === "}" || content[next] === "]") {
        continue
      }
    }

    result += character
  }

  return result
}

function parseConfig(content) {
  try {
    return JSON.parse(content)
  } catch (error) {
    const normalized = stripTrailingCommas(content)
    if (normalized === content) {
      throw error
    }
    return JSON.parse(normalized)
  }
}

const content = fs.readFileSync(configFile, "utf8")
const config = parseConfig(content)

if (Array.isArray(config.instructions)) {
  config.instructions = config.instructions.filter((item) => item !== agentsFile)
}

if (config.permission?.skill && typeof config.permission.skill === "object") {
  for (const skill of skills) {
    delete config.permission.skill[skill]
  }
}

fs.writeFileSync(configFile, JSON.stringify(config, null, 2) + "\n")
NODE
fi

echo "Removed Caveman OpenCode files from $config_dir"
