#!/usr/bin/env sh
set -eu

repo=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
source_opencode="$repo/.opencode"
config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
skills_dir="$config_dir/skills"
commands_dir="$config_dir/commands"
config_file="$config_dir/opencode.json"
agents_file="$config_dir/AGENTS.caveman.md"
skills="caveman caveman-commit caveman-review caveman-help caveman-compress"

mkdir -p "$skills_dir" "$commands_dir"

for skill in $skills; do
  rm -rf "$skills_dir/$skill"
  cp -R "$source_opencode/skills/$skill" "$skills_dir/$skill"
done

cp "$source_opencode"/commands/*.md "$commands_dir/"
cp "$source_opencode/AGENTS.md" "$agents_file"

node - "$config_file" "$agents_file" <<'NODE'
const fs = require("fs")

const [configFile, agentsFile] = process.argv.slice(2)
const skills = ["caveman", "caveman-commit", "caveman-review", "caveman-help", "caveman-compress"]
let config = {}

if (fs.existsSync(configFile)) {
  config = JSON.parse(fs.readFileSync(configFile, "utf8"))
}

config.instructions = Array.isArray(config.instructions) ? config.instructions : []
if (!config.instructions.includes(agentsFile)) {
  config.instructions.push(agentsFile)
}

config.permission = config.permission && typeof config.permission === "object" ? config.permission : {}
config.permission.skill =
  config.permission.skill && typeof config.permission.skill === "object" ? config.permission.skill : {}

for (const skill of skills) {
  config.permission.skill[skill] = "allow"
}

fs.writeFileSync(configFile, JSON.stringify(config, null, 2) + "\n")
NODE

echo "Installed Caveman for OpenCode to $config_dir"
echo "Restart OpenCode, then use /caveman, /caveman-help, /caveman-review, /caveman-commit, or /caveman-compress."
