[CmdletBinding()]
param(
    [string[]]$Dependency,
    [switch]$InstallAll,
    [switch]$VerifyOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$allDependencies = @('java', 'jadx', 'vineflower', 'dex2jar', 'apktool', 'adb')

if ($InstallAll -or -not $Dependency -or $Dependency.Count -eq 0) {
    $Dependency = $allDependencies
}

$Dependency = $Dependency | ForEach-Object { $_.ToLowerInvariant() } | Select-Object -Unique

$homeDir = [Environment]::GetFolderPath('UserProfile')
$binDir = Join-Path $homeDir 'bin'
$localShareDir = Join-Path $homeDir '.local\share'

function Write-Step {
    param([string]$Message)
    Write-Host "[STEP] $Message"
}

function Write-Ok {
    param([string]$Message)
    Write-Host "[OK] $Message"
}

function Ensure-Directory {
    param([string]$Path)
    New-Item -ItemType Directory -Force -Path $Path | Out-Null
}

function Refresh-ProcessPath {
    $machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $env:Path = (($userPath, $machinePath) -join ';').Trim(';')
}

function Add-UserPathEntry {
    param([string]$PathEntry)

    $current = [Environment]::GetEnvironmentVariable('Path', 'User')
    $entries = @()
    if ($current) {
        $entries = $current -split ';' | Where-Object { $_ }
    }

    if ($entries -contains $PathEntry) {
        return
    }

    $newValue = if ($current) { "$current;$PathEntry" } else { $PathEntry }
    [Environment]::SetEnvironmentVariable('Path', $newValue, 'User')
    Refresh-ProcessPath
}

function Set-UserEnvironmentVariable {
    param(
        [string]$Name,
        [string]$Value
    )

    [Environment]::SetEnvironmentVariable($Name, $Value, 'User')
    Set-Item -Path "Env:$Name" -Value $Value
}

function Ensure-BinDir {
    Ensure-Directory $binDir
    Add-UserPathEntry $binDir
}

function Write-BashWrapper {
    param(
        [string]$Name,
        [string]$Content
    )

    $path = Join-Path $binDir $Name
    [System.IO.File]::WriteAllText($path, $Content.Replace("`r`n", "`n"))
}

function Write-CmdWrapper {
    param(
        [string]$Name,
        [string]$Content
    )

    $path = Join-Path $binDir "$Name.cmd"
    [System.IO.File]::WriteAllText($path, $Content.Replace("`n", "`r`n"))
}

function Get-GitHubLatestRelease {
    param([string]$Repo)
    Invoke-RestMethod -Headers @{ 'User-Agent' = 'Codex' } -Uri "https://api.github.com/repos/$Repo/releases/latest"
}

function Download-File {
    param(
        [string]$Url,
        [string]$Destination
    )

    Invoke-WebRequest -Headers @{ 'User-Agent' = 'Codex' } -Uri $Url -OutFile $Destination
}

function Expand-ZipFlat {
    param(
        [string]$ZipPath,
        [string]$Destination
    )

    $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().ToString())
    Ensure-Directory $tempDir

    try {
        Expand-Archive -Path $ZipPath -DestinationPath $tempDir -Force
        if (Test-Path $Destination) {
            Remove-Item -Recurse -Force $Destination
        }
        Ensure-Directory $Destination

        $topLevel = Get-ChildItem -Path $tempDir
        if ($topLevel.Count -eq 1 -and $topLevel[0].PSIsContainer) {
            Get-ChildItem -Path $topLevel[0].FullName -Force | Move-Item -Destination $Destination -Force
        } else {
            Get-ChildItem -Path $tempDir -Force | Move-Item -Destination $Destination -Force
        }
    } finally {
        if (Test-Path $tempDir) {
            Remove-Item -Recurse -Force $tempDir
        }
    }
}

function Get-JavaMajorVersion {
    if (-not (Get-Command java -ErrorAction SilentlyContinue)) {
        return $null
    }

    $line = (cmd /c 'java -version 2>&1' | Select-Object -First 1)
    if (-not $line) {
        return $null
    }

    if ($line -match '"1\.(\d+)') {
        return [int]$Matches[1]
    }

    if ($line -match '"(\d+)') {
        return [int]$Matches[1]
    }

    return $null
}

function Install-Java {
    $major = Get-JavaMajorVersion
    if ($major -and $major -ge 17) {
        Write-Ok "Java $major already available"
        return
    }

    if ($VerifyOnly) {
        throw "Java 17+ is missing"
    }

    $winget = Get-Command winget -ErrorAction SilentlyContinue
    if (-not $winget) {
        throw "winget is required to install Java automatically on Windows"
    }

    Write-Step "Installing Java 17 with winget"
    & winget install --id EclipseAdoptium.Temurin.17.JDK --exact --accept-package-agreements --accept-source-agreements
    Refresh-ProcessPath

    $major = Get-JavaMajorVersion
    if (-not $major -or $major -lt 17) {
        throw "Java installation did not finish cleanly. Restart the shell and run the script again."
    }

    Write-Ok "Java $major installed"
}

function Install-Jadx {
    if (Get-Command jadx -ErrorAction SilentlyContinue) {
        Write-Ok "jadx already available"
        return
    }

    if ($VerifyOnly) {
        throw "jadx is missing"
    }

    $release = Get-GitHubLatestRelease 'skylot/jadx'
    $asset = $release.assets | Where-Object {
        $_.name -match '^jadx-.*\.zip$' -and $_.name -notmatch 'sources|with-jre'
    } | Select-Object -First 1

    if (-not $asset) {
        throw "Could not find a downloadable jadx zip asset"
    }

    $zipPath = Join-Path ([System.IO.Path]::GetTempPath()) $asset.name
    $targetDir = Join-Path $localShareDir 'jadx'

    Write-Step "Downloading jadx from $($asset.browser_download_url)"
    Download-File -Url $asset.browser_download_url -Destination $zipPath
    Expand-ZipFlat -ZipPath $zipPath -Destination $targetDir
    Remove-Item -Force $zipPath

    Ensure-BinDir
    Write-BashWrapper -Name 'jadx' -Content @'
#!/usr/bin/env sh
exec "$HOME/.local/share/jadx/bin/jadx" "$@"
'@
    Write-CmdWrapper -Name 'jadx' -Content @'
@echo off
call "%USERPROFILE%\.local\share\jadx\bin\jadx.bat" %*
'@

    Write-Ok "jadx installed in $targetDir"
}

function Install-Vineflower {
    if (Get-Command vineflower -ErrorAction SilentlyContinue) {
        Write-Ok "vineflower already available"
        return
    }

    if ($VerifyOnly) {
        throw "vineflower is missing"
    }

    $release = Get-GitHubLatestRelease 'Vineflower/vineflower'
    $asset = $release.assets | Where-Object { $_.name -match '^vineflower-.*\.jar$' -and $_.name -notmatch 'slim' } | Select-Object -First 1

    if (-not $asset) {
        throw "Could not find a downloadable Vineflower jar asset"
    }

    $targetDir = Join-Path $homeDir 'vineflower'
    Ensure-Directory $targetDir
    $targetJar = Join-Path $targetDir 'vineflower.jar'

    Write-Step "Downloading Vineflower from $($asset.browser_download_url)"
    Download-File -Url $asset.browser_download_url -Destination $targetJar

    Ensure-BinDir
    Set-UserEnvironmentVariable -Name 'FERNFLOWER_JAR_PATH' -Value $targetJar

    Write-BashWrapper -Name 'vineflower' -Content @'
#!/usr/bin/env sh
exec java -jar "$HOME/vineflower/vineflower.jar" "$@"
'@
    Write-CmdWrapper -Name 'vineflower' -Content @'
@echo off
java -jar "%USERPROFILE%\vineflower\vineflower.jar" %*
'@

    Write-Ok "Vineflower installed in $targetJar"
}

function Install-Dex2Jar {
    if (Get-Command d2j-dex2jar -ErrorAction SilentlyContinue) {
        Write-Ok "dex2jar already available"
        return
    }

    if ($VerifyOnly) {
        throw "dex2jar is missing"
    }

    $release = Get-GitHubLatestRelease 'pxb1988/dex2jar'
    $asset = $release.assets | Where-Object { $_.name -match '^dex-tools-.*\.zip$' } | Select-Object -First 1

    if (-not $asset) {
        throw "Could not find a downloadable dex2jar zip asset"
    }

    $zipPath = Join-Path ([System.IO.Path]::GetTempPath()) $asset.name
    $targetDir = Join-Path $localShareDir 'dex2jar'

    Write-Step "Downloading dex2jar from $($asset.browser_download_url)"
    Download-File -Url $asset.browser_download_url -Destination $zipPath
    Expand-ZipFlat -ZipPath $zipPath -Destination $targetDir
    Remove-Item -Force $zipPath

    Ensure-BinDir
    Write-BashWrapper -Name 'd2j-dex2jar' -Content @'
#!/usr/bin/env sh
exec "$HOME/.local/share/dex2jar/d2j-dex2jar.sh" "$@"
'@
    Write-CmdWrapper -Name 'd2j-dex2jar' -Content @'
@echo off
call "%USERPROFILE%\.local\share\dex2jar\d2j-dex2jar.bat" %*
'@

    Write-Ok "dex2jar installed in $targetDir"
}

function Install-Apktool {
    if (Get-Command apktool -ErrorAction SilentlyContinue) {
        Write-Ok "apktool already available"
        return
    }

    if ($VerifyOnly) {
        throw "apktool is missing"
    }

    $release = Get-GitHubLatestRelease 'iBotPeaches/Apktool'
    $asset = $release.assets | Where-Object { $_.name -match '^apktool_.*\.jar$' } | Select-Object -First 1

    if (-not $asset) {
        throw "Could not find a downloadable apktool jar asset"
    }

    $targetDir = Join-Path $localShareDir 'apktool'
    Ensure-Directory $targetDir
    $targetJar = Join-Path $targetDir 'apktool.jar'

    Write-Step "Downloading apktool from $($asset.browser_download_url)"
    Download-File -Url $asset.browser_download_url -Destination $targetJar

    Ensure-BinDir
    Write-BashWrapper -Name 'apktool' -Content @'
#!/usr/bin/env sh
exec java -jar "$HOME/.local/share/apktool/apktool.jar" "$@"
'@
    Write-CmdWrapper -Name 'apktool' -Content @'
@echo off
java -jar "%USERPROFILE%\.local\share\apktool\apktool.jar" %*
'@

    Write-Ok "apktool installed in $targetJar"
}

function Install-Adb {
    if (Get-Command adb -ErrorAction SilentlyContinue) {
        Write-Ok "adb already available"
        return
    }

    if ($VerifyOnly) {
        throw "adb is missing"
    }

    $zipPath = Join-Path ([System.IO.Path]::GetTempPath()) 'platform-tools-latest-windows.zip'
    $targetDir = Join-Path $localShareDir 'platform-tools'
    $url = 'https://dl.google.com/android/repository/platform-tools-latest-windows.zip'

    Write-Step "Downloading Android platform-tools from $url"
    Download-File -Url $url -Destination $zipPath
    Expand-ZipFlat -ZipPath $zipPath -Destination $targetDir
    Remove-Item -Force $zipPath

    Ensure-BinDir
    Write-BashWrapper -Name 'adb' -Content @'
#!/usr/bin/env sh
exec "$HOME/.local/share/platform-tools/adb.exe" "$@"
'@
    Write-CmdWrapper -Name 'adb' -Content @'
@echo off
"%USERPROFILE%\.local\share\platform-tools\adb.exe" %*
'@

    Write-Ok "adb installed in $targetDir"
}

Ensure-BinDir
Refresh-ProcessPath

$missing = @()
foreach ($dep in $Dependency) {
    switch ($dep) {
        'java' { Install-Java }
        'jadx' { Install-Jadx }
        'vineflower' { Install-Vineflower }
        'dex2jar' { Install-Dex2Jar }
        'apktool' { Install-Apktool }
        'adb' { Install-Adb }
        default { throw "Unsupported dependency: $dep" }
    }
}

foreach ($dep in $Dependency) {
    switch ($dep) {
        'java' {
            if (-not (Get-JavaMajorVersion)) { $missing += $dep }
        }
        'jadx' {
            if (-not (Get-Command jadx -ErrorAction SilentlyContinue)) { $missing += $dep }
        }
        'vineflower' {
            if (-not (Get-Command vineflower -ErrorAction SilentlyContinue)) { $missing += $dep }
        }
        'dex2jar' {
            if (-not (Get-Command d2j-dex2jar -ErrorAction SilentlyContinue)) { $missing += $dep }
        }
        'apktool' {
            if (-not (Get-Command apktool -ErrorAction SilentlyContinue)) { $missing += $dep }
        }
        'adb' {
            if (-not (Get-Command adb -ErrorAction SilentlyContinue)) { $missing += $dep }
        }
    }
}

if ($missing.Count -gt 0) {
    throw "Missing dependencies after installation: $($missing -join ', ')"
}

Write-Ok "Completed successfully. Restart PowerShell or Git Bash before running the skill."
