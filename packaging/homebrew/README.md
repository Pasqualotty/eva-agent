# Homebrew packaging — EVA Agent

MIT-licensed fork of [Nous Research Hermes Agent](https://github.com/NousResearch/hermes-agent).
Copyright (c) 2025 Nous Research is preserved in the root `LICENSE`.

| Formula | Purpose |
|---------|---------|
| `eva-agent.rb` | **EVA** brand formula (this fork) |
| `hermes-agent.rb` | Upstream-shaped reference formula |

## EVA formula notes

- Source should eventually point at a **semver sdist** asset on GitHub Releases for `Pasqualotty/eva-agent`, not a floating `main` tarball.
- Wrapper exports `HERMES_BUNDLED_SKILLS`, `HERMES_OPTIONAL_SKILLS`, and `HERMES_MANAGED=homebrew` so the engine keeps finding bundled assets (env names remain `HERMES_*` for compatibility with the core).
- Console scripts: prefer `eva`; keep `hermes` / `hermes-agent` / `hermes-acp` when the package still ships them.

## Update flow

1. Bump formula `url`, `version`, and `sha256` for a real release asset.
2. `brew update-python-resources --print-only eva-agent`
3. Keep `ignore_packages: %w[certifi cryptography pydantic]`
4. `brew audit --new --strict eva-agent` and `brew test eva-agent`
