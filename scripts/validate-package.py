#!/usr/bin/env python3
"""Validate the OpenCode Caveman package before release."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OPENCODE_DIR = ROOT / ".opencode"
SKILLS = [
    "caveman",
    "caveman-commit",
    "caveman-review",
    "caveman-help",
    "caveman-compress",
]
COMMANDS = SKILLS


def fail(message: str) -> None:
    print(f"FAIL: {message}")
    raise SystemExit(1)


def require_file(path: Path) -> None:
    if not path.is_file():
        fail(f"missing file: {path.relative_to(ROOT)}")


def require_dir(path: Path) -> None:
    if not path.is_dir():
        fail(f"missing directory: {path.relative_to(ROOT)}")


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def parse_frontmatter(path: Path) -> dict[str, str]:
    text = read(path)
    if not text.startswith("---\n"):
        fail(f"missing frontmatter: {path.relative_to(ROOT)}")

    try:
        _, body = text.split("---\n", 1)
        raw_frontmatter, _ = body.split("\n---\n", 1)
    except ValueError:
        fail(f"invalid frontmatter delimiters: {path.relative_to(ROOT)}")

    data: dict[str, str] = {}
    current_key: str | None = None
    current_value: list[str] = []

    def flush() -> None:
        nonlocal current_key, current_value
        if current_key is not None:
            data[current_key] = "\n".join(current_value).strip()
        current_key = None
        current_value = []

    for line in raw_frontmatter.splitlines():
        if line.startswith("  ") and current_key is not None:
            current_value.append(line.strip())
            continue

        flush()
        match = re.match(r"^([A-Za-z0-9_-]+):\s*(.*)$", line)
        if not match:
            fail(f"unsupported frontmatter line in {path.relative_to(ROOT)}: {line}")

        current_key = match.group(1)
        value = match.group(2).strip()
        if value == ">":
            current_value = []
        else:
            current_value = [value]

    flush()
    return data


def validate_opencode_json() -> None:
    path = ROOT / "opencode.json"
    require_file(path)
    config = json.loads(read(path))

    if config.get("$schema") != "https://opencode.ai/config.json":
        fail("opencode.json has missing or unexpected $schema")

    if config.get("instructions") != [".opencode/AGENTS.md"]:
        fail("opencode.json instructions must point at .opencode/AGENTS.md")

    allowed = config.get("permission", {}).get("skill", {})
    missing = [skill for skill in SKILLS if allowed.get(skill) != "allow"]
    if missing:
        fail(f"opencode.json does not allow skills: {', '.join(missing)}")


def validate_commands() -> None:
    commands_dir = OPENCODE_DIR / "commands"
    require_dir(commands_dir)

    for command in COMMANDS:
        path = commands_dir / f"{command}.md"
        require_file(path)
        frontmatter = parse_frontmatter(path)
        if not frontmatter.get("description"):
            fail(f"command missing description: {path.relative_to(ROOT)}")


def validate_skills() -> None:
    skills_dir = OPENCODE_DIR / "skills"
    require_dir(skills_dir)

    for skill in SKILLS:
        path = skills_dir / skill / "SKILL.md"
        require_file(path)
        frontmatter = parse_frontmatter(path)
        if frontmatter.get("name") != skill:
            fail(f"skill name mismatch in {path.relative_to(ROOT)}")
        if not frontmatter.get("description"):
            fail(f"skill missing description: {path.relative_to(ROOT)}")

    compress_skill = read(skills_dir / "caveman-compress" / "SKILL.md")
    if "/caveman:compress" in compress_skill:
        fail("caveman-compress skill still documents /caveman:compress")


def validate_installers() -> None:
    for path in [
        ROOT / "install-opencode.ps1",
        ROOT / "uninstall-opencode.ps1",
        ROOT / "install-opencode.sh",
        ROOT / "uninstall-opencode.sh",
    ]:
        require_file(path)
        text = read(path)
        missing = [skill for skill in SKILLS if skill not in text]
        if missing:
            fail(f"{path.name} does not mention skills: {', '.join(missing)}")


def validate_python_scripts() -> None:
    scripts_dir = OPENCODE_DIR / "skills" / "caveman-compress" / "scripts"
    require_dir(scripts_dir)

    for path in sorted(scripts_dir.glob("*.py")):
        compile(read(path), str(path), "exec")


def main() -> int:
    require_file(OPENCODE_DIR / "AGENTS.md")
    validate_opencode_json()
    validate_commands()
    validate_skills()
    validate_installers()
    validate_python_scripts()
    print("Package validation passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
