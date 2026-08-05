#!/usr/bin/env sh
set -eu

repo=$(CDPATH= cd -- "$(dirname -- "$0")" 2>/dev/null && pwd || pwd)
source_opencode="$repo/.opencode"
cleanup_dir=""
config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
skills_dir="$config_dir/skills"
commands_dir="$config_dir/commands"
config_file="$config_dir/opencode.json"
agents_file="$config_dir/AGENTS.caveman.md"
skills="caveman caveman-commit caveman-review caveman-help caveman-compress"
default_level="${CAVEMAN_OPENCODE_DEFAULT_LEVEL:-full}"

case "$default_level" in
  lite|full|ultra|wenyan|wenyan-lite|wenyan-ultra) ;;
  *)
    echo "ERROR: CAVEMAN_OPENCODE_DEFAULT_LEVEL must be one of: lite, full, ultra, wenyan, wenyan-lite, wenyan-ultra" >&2
    exit 1
    ;;
esac

cleanup() {
  if [ -n "$cleanup_dir" ] && [ -d "$cleanup_dir" ]; then
    rm -rf "$cleanup_dir"
  fi
}
trap cleanup EXIT

if [ ! -f "$source_opencode/AGENTS.md" ]; then
  archive_url="${CAVEMAN_OPENCODE_ARCHIVE_URL:-https://github.com/anthonystepvoy/caveman-opencode/archive/refs/heads/main.tar.gz}"
  cleanup_dir="${TMPDIR:-/tmp}/caveman-opencode-$$"
  archive_file="$cleanup_dir/source.tar.gz"
  mkdir -p "$cleanup_dir"

  echo "Downloading Caveman for OpenCode from $archive_url"
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$archive_url" -o "$archive_file"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "$archive_file" "$archive_url"
  else
    echo "ERROR: curl or wget is required for remote install" >&2
    exit 1
  fi

  tar -xzf "$archive_file" -C "$cleanup_dir"
  source_dir=$(find "$cleanup_dir" -mindepth 1 -maxdepth 1 -type d | head -n 1)
  if [ -z "$source_dir" ]; then
    echo "ERROR: downloaded archive did not contain a source directory" >&2
    exit 1
  fi

  source_opencode="$source_dir/.opencode"
  if [ ! -f "$source_opencode/AGENTS.md" ]; then
    echo "ERROR: downloaded archive did not contain .opencode/AGENTS.md" >&2
    exit 1
  fi
fi

mkdir -p "$skills_dir" "$commands_dir"

for skill in $skills; do
  rm -rf "$skills_dir/$skill"
  cp -R "$source_opencode/skills/$skill" "$skills_dir/$skill"
done

cp "$source_opencode"/commands/*.md "$commands_dir/"
sed "s/^Default mode: full\./Default mode: $default_level./" "$source_opencode/AGENTS.md" > "$agents_file"

node - "$config_file" "$agents_file" <<'NODE'
const fs = require("fs")

const [configFile, agentsFile] = process.argv.slice(2)
const skills = ["caveman", "caveman-commit", "caveman-review", "caveman-help", "caveman-compress"]
let config = {}

if (fs.existsSync(configFile)) {
  const content = fs.readFileSync(configFile, "utf8")
  try {
    config = JSON.parse(content)
  } catch (e) {
    config = JSON.parse(content.replace(/,\s*([\]}])/g, "$1"))
  }
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
echo "Default Caveman intensity: $default_level"
echo "Restart OpenCode, then use /caveman, /caveman-help, /caveman-review, /caveman-commit, or /caveman-compress."
