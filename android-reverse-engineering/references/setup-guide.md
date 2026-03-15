# Setup Guide: Dependencies for Android Reverse Engineering

Use this guide to install the toolchain required by the Codex skill.

Required:

- Java JDK 17+
- `jadx`

Recommended:

- `vineflower` or another Fernflower-compatible JAR
- `dex2jar`
- `apktool`
- `adb`

## Windows

### Recommended Windows Path

1. Install Git for Windows so you have Git Bash:

```powershell
winget install --id Git.Git --exact
```

2. Install the Codex skill into `~/.codex/skills/android-reverse-engineering`.

3. Run the bundled Windows helper:

```powershell
powershell -ExecutionPolicy Bypass -File "$HOME/.codex/skills/android-reverse-engineering/scripts/install-deps-windows.ps1" -InstallAll
```

4. Restart your shell after the installer updates user-level environment variables.

5. Verify from Git Bash:

```bash
bash "$HOME/.codex/skills/android-reverse-engineering/scripts/check-deps.sh"
```

### Manual Windows Installation

If you do not want to use the PowerShell helper, install each dependency manually:

#### Java JDK 17+

Recommended:

```powershell
winget install --id EclipseAdoptium.Temurin.17.JDK --exact
```

Verify:

```powershell
java -version
```

#### jadx

1. Download the latest Windows release from <https://github.com/skylot/jadx/releases/latest>
2. Extract it to a stable directory, for example `C:\Users\<you>\.local\share\jadx`
3. Add `C:\Users\<you>\.local\share\jadx\bin` to your `PATH`

Verify:

```powershell
jadx --version
```

#### Vineflower

1. Download the latest JAR from <https://github.com/Vineflower/vineflower/releases/latest>
2. Save it as `C:\Users\<you>\vineflower\vineflower.jar`
3. Set `FERNFLOWER_JAR_PATH`

```powershell
setx FERNFLOWER_JAR_PATH "C:\Users\<you>\vineflower\vineflower.jar"
```

Verify:

```powershell
java -jar "$env:FERNFLOWER_JAR_PATH" --version
```

#### dex2jar

1. Download the latest release from <https://github.com/pxb1988/dex2jar/releases/latest>
2. Extract it to a stable directory
3. Add the extracted directory to `PATH`

Verify:

```powershell
d2j-dex2jar --help
```

#### apktool

1. Download the latest JAR from <https://github.com/iBotPeaches/Apktool/releases/latest>
2. Save it somewhere stable, for example `C:\Users\<you>\.local\share\apktool\apktool.jar`
3. Create an `apktool.cmd` wrapper or invoke it with `java -jar`

Verify:

```powershell
java -jar C:\Users\<you>\.local\share\apktool\apktool.jar --version
```

#### adb

Recommended:

```powershell
winget install --id Google.PlatformTools --exact
```

Verify:

```powershell
adb version
```

## Ubuntu / Debian

Install Java:

```bash
sudo apt update
sudo apt install openjdk-17-jdk
```

Install optional tools from packages where available:

```bash
sudo apt install adb apktool
```

Install the rest through the bundled helper after the skill is copied into `~/.codex/skills`:

```bash
bash ~/.codex/skills/android-reverse-engineering/scripts/install-dep.sh jadx
bash ~/.codex/skills/android-reverse-engineering/scripts/install-dep.sh vineflower
bash ~/.codex/skills/android-reverse-engineering/scripts/install-dep.sh dex2jar
```

Verify:

```bash
bash ~/.codex/skills/android-reverse-engineering/scripts/check-deps.sh
```

## Fedora

Install Java:

```bash
sudo dnf install java-17-openjdk-devel
```

Optional packages:

```bash
sudo dnf install android-tools apktool
```

Then use the bundled helper for the remaining tools:

```bash
bash ~/.codex/skills/android-reverse-engineering/scripts/install-dep.sh jadx
bash ~/.codex/skills/android-reverse-engineering/scripts/install-dep.sh vineflower
bash ~/.codex/skills/android-reverse-engineering/scripts/install-dep.sh dex2jar
```

## Arch Linux

Install Java and adb:

```bash
sudo pacman -S jdk17-openjdk android-tools
```

Install the rest with the bundled helper:

```bash
bash ~/.codex/skills/android-reverse-engineering/scripts/install-dep.sh jadx
bash ~/.codex/skills/android-reverse-engineering/scripts/install-dep.sh vineflower
bash ~/.codex/skills/android-reverse-engineering/scripts/install-dep.sh dex2jar
bash ~/.codex/skills/android-reverse-engineering/scripts/install-dep.sh apktool
```

## macOS

Install Java:

```bash
brew install openjdk@17
```

Install available optional tools:

```bash
brew install android-platform-tools apktool
```

Install the rest with the bundled helper:

```bash
bash ~/.codex/skills/android-reverse-engineering/scripts/install-dep.sh jadx
bash ~/.codex/skills/android-reverse-engineering/scripts/install-dep.sh vineflower
bash ~/.codex/skills/android-reverse-engineering/scripts/install-dep.sh dex2jar
```

If Homebrew asks you to update your shell profile for Java, do that before verifying.

## Verification

Run the dependency checker:

```bash
bash ~/.codex/skills/android-reverse-engineering/scripts/check-deps.sh
```

Expected result:

- `Java` and `jadx` must be detected.
- `vineflower`, `dex2jar`, `apktool`, and `adb` should also be detected for the best workflow.

## Troubleshooting

| Problem | Fix |
|---|---|
| `jadx: command not found` | Ensure the jadx `bin` directory is on `PATH`, or reinstall it with the helper |
| `java` is present but the wrong version | Install JDK 17+ and restart the shell |
| `FERNFLOWER_JAR_PATH` is missing | Point it at the Vineflower or Fernflower JAR and restart the shell |
| `d2j-dex2jar` is missing | Add the extracted dex2jar directory to `PATH` |
| `adb` is missing on Windows | Install `Google.PlatformTools` with `winget` or extract platform-tools manually |
