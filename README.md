<div align="center">

# Caveman for OpenCode

### Terse AI responses, slash commands, and token-saving skills for OpenCode

[![GitHub stars](https://img.shields.io/github/stars/anthonystepvoy/caveman-opencode?style=social)](https://github.com/anthonystepvoy/caveman-opencode/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/anthonystepvoy/caveman-opencode?style=social)](https://github.com/anthonystepvoy/caveman-opencode/fork)
[![MIT License](https://img.shields.io/github/license/anthonystepvoy/caveman-opencode)](LICENSE)
[![Issues](https://img.shields.io/github/issues/anthonystepvoy/caveman-opencode)](https://github.com/anthonystepvoy/caveman-opencode/issues)

**why use many token when few do trick**

OpenCode packaging for Caveman-style compressed responses, quick commands, terse reviews, commit messages, and markdown memory compression.

[Install](#install) · [Commands](#commands) · [What installs](#what-installs) · [Credits](#credits)

</div>

---

## What is this?

`caveman-opencode` is an OpenCode-focused package adapted from [JuliusBrussee/caveman](https://github.com/JuliusBrussee/caveman).

It gives OpenCode a small set of commands and skills for terse, high-signal AI responses:

- `/caveman` - switch terse response mode on or change intensity.
- `/caveman-help` - show a quick reference card.
- `/caveman-review` - produce compact review findings.
- `/caveman-commit` - generate terse Conventional Commit messages.
- `/caveman-compress` - compress markdown memory files while preserving technical content.

This repo is not the full upstream multi-agent Caveman repository. It is a focused OpenCode distribution.

## Why use it?

AI agents often spend too many tokens on filler, hedging, and long explanations. Caveman mode keeps technical substance but removes excess wording.

Useful when you want:

- Shorter agent responses.
- Less chatty debugging.
- Compact review comments.
- Faster commit message drafting.
- Smaller markdown memory files.

It does not make the model smarter and it should not be used where compression could make instructions ambiguous.

## Install

Clone this repo:

```bash
git clone https://github.com/anthonystepvoy/caveman-opencode.git
cd caveman-opencode
```

Windows:

```powershell
powershell -ExecutionPolicy Bypass -File .\install-opencode.ps1
```

macOS/Linux:

```bash
chmod +x ./install-opencode.sh
./install-opencode.sh
```

Restart OpenCode after installing.

## Validate

Before publishing a release, run the package validation script:

```bash
python scripts/validate-package.py
```

It checks OpenCode config, command frontmatter, skill metadata, installer coverage, and Python script syntax.

## Commands

Enable Caveman mode:

```text
/caveman
```

Choose intensity:

```text
/caveman lite
/caveman full
/caveman ultra
/caveman wenyan
/caveman wenyan-lite
/caveman wenyan-ultra
```

Other commands:

```text
/caveman-help
/caveman-review
/caveman-commit
/caveman-compress path/to/memory.md
```

Turn Caveman mode off:

```text
normal mode
```

or:

```text
stop caveman
```

## What installs

The installer copies OpenCode-ready files into `~/.config/opencode/`:

```text
.opencode/AGENTS.md                    -> AGENTS.caveman.md
.opencode/commands/*.md                -> commands/
.opencode/skills/*                     -> skills/
```

It also merges Caveman skill permissions into:

```text
~/.config/opencode/opencode.json
```

The repo includes `opencode.json` for local testing. If you open OpenCode inside this repository, it can load Caveman directly from `.opencode/`.

## Uninstall

Windows:

```powershell
powershell -ExecutionPolicy Bypass -File .\uninstall-opencode.ps1
```

macOS/Linux:

```bash
chmod +x ./uninstall-opencode.sh
./uninstall-opencode.sh
```

## Repository layout

```text
.opencode/
  AGENTS.md
  commands/
  skills/
install-opencode.ps1
install-opencode.sh
uninstall-opencode.ps1
uninstall-opencode.sh
opencode.json
```

## Safety notes

- Compression can make text harder to read if overused.
- Security warnings, destructive operations, and multi-step confirmations should stay explicit.
- Code blocks, commands, error messages, identifiers, and legal/security text should remain exact.
- Always review compressed memory files before relying on them.

## Credits

This project packages OpenCode-compatible commands and skills adapted from:

[JuliusBrussee/caveman](https://github.com/JuliusBrussee/caveman)

Original concept, prompts, and compression logic belong to the upstream Caveman project and its contributors. This repository focuses on OpenCode installation and packaging.

See [NOTICE.md](NOTICE.md) for attribution details.

## License

MIT. See [LICENSE](LICENSE).
