# Contributing

Thanks for improving `caveman-opencode`.

This repository should stay focused on OpenCode packaging for Caveman-style terse AI responses. Keep changes small, practical, and easy to install.

## Good contributions

- OpenCode command improvements.
- OpenCode skill wording fixes.
- Installer and uninstaller fixes for Windows, macOS, and Linux.
- Clear docs for installation and usage.
- Safety improvements for compression behavior.

## Avoid

- Rebuilding the full upstream Caveman multi-agent repository here.
- Adding unrelated agent platforms to this repo.
- Adding heavy frameworks or complex packaging.
- Making unsupported benchmark claims.
- Removing upstream attribution.

## Pull request checklist

- The change is OpenCode-specific or clearly useful for OpenCode users.
- README and command docs stay accurate.
- Install and uninstall behavior is preserved.
- Upstream Caveman attribution remains intact.
- No generated caches, `node_modules`, or `__pycache__` files are committed.
