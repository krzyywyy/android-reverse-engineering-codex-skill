# Android Reverse Engineering Codex Skill

This repository is a Codex-focused adaptation of the Android reverse engineering skill originally created by Simone Avogadro for Claude Code.

Original upstream project:

- `https://github.com/SimoneAvogadro/android-reverse-engineering-skill`

This repository does not claim to be the original work. It republishes a modified version of that skill in a Codex-friendly layout, preserves Apache 2.0 licensing, and keeps attribution to the upstream author.

## What Changed Compared To The Claude Version

- Converted the Claude plugin layout into a Codex skill layout.
- Rewrote `SKILL.md` frontmatter and instructions for Codex triggering.
- Added `agents/openai.yaml` metadata for Codex.
- Removed Claude-specific plugin manifests and slash-command files.
- Added Windows-specific setup notes for Codex users.
- Added a PowerShell helper to install the Windows dependency toolchain.

## Repository Layout

```text
android-reverse-engineering-codex-skill/
|- android-reverse-engineering/
|  |- SKILL.md
|  |- agents/openai.yaml
|  |- scripts/
|  |- references/
|- LICENSE
|- NOTICE
`- README.md
```

The actual Codex skill is the [`android-reverse-engineering`](./android-reverse-engineering) folder.

## Step-By-Step Installation

Choose the path that matches your system.

### Windows

1. Install Git for Windows so you have Git Bash:

```powershell
winget install --id Git.Git --exact
```

2. Clone this repository:

```powershell
git clone https://github.com/krzyywyy/android-reverse-engineering-codex-skill.git
cd android-reverse-engineering-codex-skill
```

3. Install the skill into Codex:

```powershell
New-Item -ItemType Directory -Force -Path "$HOME/.codex/skills" | Out-Null
Copy-Item -Recurse -Force ".\android-reverse-engineering" "$HOME/.codex/skills\"
```

4. Restart Codex so it can discover the new skill.

5. Install the reverse-engineering dependencies. The PowerShell helper installs Java 17, `jadx`, `vineflower`, `dex2jar`, `apktool`, and `adb` into a user-local layout:

```powershell
powershell -ExecutionPolicy Bypass -File ".\android-reverse-engineering\scripts\install-deps-windows.ps1" -InstallAll
```

6. Verify the installation from Git Bash:

```bash
bash "$HOME/.codex/skills/android-reverse-engineering/scripts/check-deps.sh"
```

If you prefer not to use the helper script, follow the manual instructions in [`android-reverse-engineering/references/setup-guide.md`](./android-reverse-engineering/references/setup-guide.md).

### macOS Or Linux

1. Clone this repository:

```bash
git clone https://github.com/krzyywyy/android-reverse-engineering-codex-skill.git
cd android-reverse-engineering-codex-skill
```

2. Install the skill into Codex:

```bash
mkdir -p ~/.codex/skills
cp -R ./android-reverse-engineering ~/.codex/skills/
```

3. Restart Codex so it can discover the new skill.

4. Check which dependencies are missing:

```bash
bash ~/.codex/skills/android-reverse-engineering/scripts/check-deps.sh
```

5. Install the required tools:

```bash
bash ~/.codex/skills/android-reverse-engineering/scripts/install-dep.sh java
bash ~/.codex/skills/android-reverse-engineering/scripts/install-dep.sh jadx
```

6. Install the recommended optional tools:

```bash
bash ~/.codex/skills/android-reverse-engineering/scripts/install-dep.sh vineflower
bash ~/.codex/skills/android-reverse-engineering/scripts/install-dep.sh dex2jar
bash ~/.codex/skills/android-reverse-engineering/scripts/install-dep.sh apktool
bash ~/.codex/skills/android-reverse-engineering/scripts/install-dep.sh adb
```

7. Run the dependency check again:

```bash
bash ~/.codex/skills/android-reverse-engineering/scripts/check-deps.sh
```

### Alternative: Install Directly From GitHub Into Codex

If your Codex installation already contains the system `skill-installer`, you can install this public repository directly:

```bash
python ~/.codex/skills/.system/skill-installer/scripts/install-skill-from-github.py \
  --repo krzyywyy/android-reverse-engineering-codex-skill \
  --path android-reverse-engineering
```

On Windows, replace `python` with `py -3` if needed.

## How To Use The Skill

After installation and restart, Codex can trigger the skill from natural language prompts or from an explicit skill mention.

### Natural Language Examples

- `Decompile this APK and list all API endpoints.`
- `Reverse engineer this Android app and trace the login flow.`
- `Analyze this AAR library and show network calls.`
- `Find Retrofit endpoints in this decompiled app.`

### Explicit Invocation Example

```text
Use $android-reverse-engineering to decompile this APK, inspect the manifest, and document its API endpoints.
```

### Direct Script Usage

You can also run the bundled scripts without waiting for automatic skill triggering:

```bash
SKILL_DIR="${CODEX_HOME:-$HOME/.codex}/skills/android-reverse-engineering"

# Check dependencies
bash "$SKILL_DIR/scripts/check-deps.sh"

# Decompile an APK
bash "$SKILL_DIR/scripts/decompile.sh" app-release.apk

# Run both decompilers side by side
bash "$SKILL_DIR/scripts/decompile.sh" --engine both --deobf app-release.apk

# Search extracted sources for API calls
bash "$SKILL_DIR/scripts/find-api-calls.sh" app-release-decompiled/sources/
```

### Expected Output

The workflow is designed to produce:

1. Decompiled sources and resources.
2. An architecture summary of the app or library.
3. Extracted API endpoints and auth patterns.
4. Call-flow traces from entry points to the network layer.

## Complete Dependency Setup

Detailed setup instructions live in:

- [`android-reverse-engineering/references/setup-guide.md`](./android-reverse-engineering/references/setup-guide.md)

That guide explains:

- how to install Java 17+
- how to install `jadx`
- how to install `vineflower` / `fernflower`
- how to install `dex2jar`
- how to install `apktool`
- how to install `adb`
- how to verify the environment

## Legal And Attribution Notes

Use this skill only on software that you own or are explicitly authorized to inspect.

This repository is based on Simone Avogadro's Claude-oriented skill and is distributed here as a modified Codex port under the original Apache 2.0 license terms.
