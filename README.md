# Android Reverse Engineering Codex Skill

Codex adaptation of the original Claude-oriented Android reverse engineering skill by Simone Avogadro.

This repository contains a single Codex skill in [android-reverse-engineering](./android-reverse-engineering) with:

- Codex-compatible `SKILL.md` frontmatter and triggering description
- `agents/openai.yaml` metadata for Codex UI
- Claude-specific plugin and slash-command pieces removed
- Codex-friendly script paths and Windows/Git Bash notes

## Origin

Original upstream repository:

- `https://github.com/SimoneAvogadro/android-reverse-engineering-skill`

This adaptation keeps the original Apache 2.0 licensing and preserves attribution.

## Install

Manual install:

1. Copy [android-reverse-engineering](./android-reverse-engineering) into `~/.codex/skills/`
2. Restart Codex

## Contents

- [android-reverse-engineering/SKILL.md](./android-reverse-engineering/SKILL.md)
- [android-reverse-engineering/agents/openai.yaml](./android-reverse-engineering/agents/openai.yaml)
- [android-reverse-engineering/scripts](./android-reverse-engineering/scripts)
- [android-reverse-engineering/references](./android-reverse-engineering/references)
