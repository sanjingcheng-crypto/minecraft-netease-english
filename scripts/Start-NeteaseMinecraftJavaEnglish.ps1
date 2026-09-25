[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$LauncherPath,
    [Parameter(Mandatory = $true)]
    [string]$GameRoot,
    [Parameter(Mandatory = $true)]
    [string]$JavaPath,
    [string]$GameProcessMarker,
    [string]$BackupRoot = (Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'MinecraftEnglishBackups'),
    [switch]$SoftwareOpenGL,
    [switch]$AuditOnly
)

$ErrorActionPreference = 'Stop'
$launcherPathResolved = (Resolve-Path -LiteralPath $LauncherPath).Path
$gameRootResolved = (Resolve-Path -LiteralPath $GameRoot).Path
$javaPathResolved = (Resolve-Path -LiteralPath $JavaPath).Path
$optionsPath = Join-Path $gameRootResolved 'options.txt'
if (-not (Test-Path -LiteralPath $optionsPath -PathType Leaf)) {
    throw "Java options.txt not found: $optionsPath"
}
if (-not $GameProcessMarker) {
    $GameProcessMarker = Split-Path $gameRootResolved -Leaf
}

function Get-LauncherProcess {
    Get-CimInstance Win32_Process -Filter "Name = '$([IO.Path]::GetFileName($launcherPathResolved))'" |
        Where-Object { $_.ExecutablePath -ieq $launcherPathResolved }
}

function Get-GameProcess {
    Get-CimInstance Win32_Process -Filter "Name = '$([IO.Path]::GetFileName($javaPathResolved))'" |
        Where-Object {
            $_.ExecutablePath -ieq $javaPathResolved -and
            $_.CommandLine -match [regex]::Escape($GameProcessMarker)
        }
}

$initialText = [IO.File]::ReadAllText($optionsPath)
$languageLines = [regex]::Matches($initialText, '(?m)^lang:[^\r\n]*')
if ($languageLines.Count -ne 1) {
    throw "Expected one Java language setting, found $($languageLines.Count): $optionsPath"
}

if ($AuditOnly) {
    Write-Output "Launcher: $launcherPathResolved"
    Write-Output "Game root: $gameRootResolved"
    Write-Output "Java executable: $javaPathResolved"
    Write-Output "Process marker: $GameProcessMarker"
    Write-Output "Language: $($languageLines[0].Value)"
    Write-Output "Read-only: $((Get-Item -LiteralPath $optionsPath).IsReadOnly)"
    Write-Output "Launcher running: $([bool](Get-LauncherProcess))"
    Write-Output "Game running: $([bool](Get-GameProcess))"
    return
}

if (Get-LauncherProcess) { throw 'Close the existing NetEase launcher before using this helper.' }
if (Get-GameProcess) { throw 'Close the running Java game before using this helper.' }

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$backupDir = Join-Path $BackupRoot "$stamp-$([guid]::NewGuid().ToString('N').Substring(0, 6))"
$null = New-Item -ItemType Directory -Path $backupDir -Force
Copy-Item -LiteralPath $optionsPath -Destination (Join-Path $backupDir 'options.txt') -Force
Write-Output "Java options backup: $backupDir"

function Set-EnglishLanguage {
    $item = Get-Item -LiteralPath $optionsPath
    $item.IsReadOnly = $false
    $bytes = [IO.File]::ReadAllBytes($optionsPath)
    $hasBom = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF
    $encoding = [Text.UTF8Encoding]::new($hasBom, $true)
    $text = $encoding.GetString($bytes, $(if ($hasBom) { 3 } else { 0 }), $bytes.Length - $(if ($hasBom) { 3 } else { 0 }))
    $matches = [regex]::Matches($text, '(?m)^lang:[^\r\n]*')
    if ($matches.Count -ne 1) { throw "Java language setting changed unexpectedly: $optionsPath" }
    $updated = [regex]::Replace($text, '(?m)^lang:[^\r\n]*', 'lang:en_us')
    if ($updated -cne $text) {
        [IO.File]::WriteAllText($optionsPath, $updated, $encoding)
    }
}

Set-EnglishLanguage
(Get-Item -LiteralPath $optionsPath).IsReadOnly = $true

try {
    if ($SoftwareOpenGL) {
        $env:GALLIUM_DRIVER = 'llvmpipe'
        $env:LIBGL_ALWAYS_SOFTWARE = 'true'
    }
    $launcher = Start-Process -FilePath $launcherPathResolved -WorkingDirectory (Split-Path $launcherPathResolved) -PassThru

    # Protect the language while the launcher rewrites options.txt; release
    # the file after the game window appears so normal settings can save.
    while (Get-Process -Id $launcher.Id -ErrorAction SilentlyContinue) {
        $game = Get-GameProcess | Select-Object -First 1
        if ($game) {
            do {
                Start-Sleep -Seconds 1
                $gameWindow = Get-Process -Id $game.ProcessId -ErrorAction SilentlyContinue
            } while ($gameWindow -and -not $gameWindow.MainWindowTitle)

            if ($gameWindow) {
                (Get-Item -LiteralPath $optionsPath).IsReadOnly = $false
                do {
                    Start-Sleep -Seconds 2
                    $gameWindow = Get-Process -Id $game.ProcessId -ErrorAction SilentlyContinue
                } while ($gameWindow)
            }

            Set-EnglishLanguage
            (Get-Item -LiteralPath $optionsPath).IsReadOnly = $true
        }
        Start-Sleep -Seconds 1
    }
}
finally {
    # Closing the launcher does not necessarily close the game.
    while (Get-GameProcess) { Start-Sleep -Seconds 2 }
    if (Test-Path -LiteralPath $optionsPath) {
        Set-EnglishLanguage
        (Get-Item -LiteralPath $optionsPath).IsReadOnly = $true
    }
}
