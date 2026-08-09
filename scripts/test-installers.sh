#!/usr/bin/env sh
set -eu

repo=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
test_root=$(mktemp -d "${TMPDIR:-/tmp}/caveman-opencode-test.XXXXXX")
config_home="$test_root/config"
config_dir="$config_home/opencode"
config_file="$config_dir/opencode.json"
agents_file="$config_dir/AGENTS.caveman.md"

cleanup() {
  rm -rf "$test_root"
}
trap cleanup EXIT

mkdir -p "$config_dir"

node - "$config_file" <<'NODE'
const fs = require("fs")

const [configFile] = process.argv.slice(2)
fs.writeFileSync(
  configFile,
  `{
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
`,
)
NODE

CAVEMAN_OPENCODE_DEFAULT_LEVEL=ultra XDG_CONFIG_HOME="$config_home" sh "$repo/install-opencode.sh"

node - "$config_file" "$agents_file" <<'NODE'
const assert = require("assert").strict
const fs = require("fs")

const [configFile, agentsFile] = process.argv.slice(2)
const config = JSON.parse(fs.readFileSync(configFile, "utf8"))
const skills = ["caveman", "caveman-commit", "caveman-review", "caveman-help", "caveman-compress"]

assert.deepEqual(config.instructions, ["keep.md", agentsFile])
assert.equal(config.custom, "literal,}")
assert.equal(config.nested.value, "literal,]")
assert.equal(config.permission.skill.existing, "allow")
for (const skill of skills) {
  assert.equal(config.permission.skill[skill], "allow")
}
assert.match(fs.readFileSync(agentsFile, "utf8"), /^Default mode: ultra\./m)
NODE

XDG_CONFIG_HOME="$config_home" sh "$repo/uninstall-opencode.sh"

node - "$config_file" "$agents_file" <<'NODE'
const assert = require("assert").strict
const fs = require("fs")

const [configFile, agentsFile] = process.argv.slice(2)
const config = JSON.parse(fs.readFileSync(configFile, "utf8"))
const skills = ["caveman", "caveman-commit", "caveman-review", "caveman-help", "caveman-compress"]

assert.deepEqual(config.instructions, ["keep.md"])
assert.equal(config.custom, "literal,}")
assert.equal(config.nested.value, "literal,]")
assert.equal(config.permission.skill.existing, "allow")
for (const skill of skills) {
  assert.equal(config.permission.skill[skill], undefined)
}
assert.equal(fs.existsSync(agentsFile), false)
console.log("POSIX installer tests passed.")
NODE
