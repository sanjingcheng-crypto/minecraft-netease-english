[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$GameRoot,
    [string]$OptionsPath = (Join-Path $env:APPDATA 'MinecraftPE_Netease\minecraftpe\options.txt'),
    [string]$BackupRoot = (Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'MinecraftEnglishBackups'),
    [switch]$AuditOnly
)

$ErrorActionPreference = 'Stop'
# Packaged desktop apps can redirect a normal AppData path to their private copy.
# The extended-length local path addresses the real Windows user profile file.
if ($OptionsPath -match '^[A-Za-z]:\\') {
    $OptionsPath = '\\?\' + [IO.Path]::GetFullPath($OptionsPath)
}
$gameRootResolved = (Resolve-Path -LiteralPath $GameRoot).Path
$exe = Join-Path $gameRootResolved 'Minecraft.Windows.exe'
$pack = Join-Path $gameRootResolved 'data\resource_packs\vanilla_netease'
$manifestPath = Join-Path $pack 'texts\languages.json'
$langPath = Join-Path $pack 'texts\zh_CN.lang'
$generalPath = Join-Path $pack 'ui\settings_sections\general_section.json'
$modPath = Join-Path $pack 'ui\netease\mod\netease_general_setting.json'
$required = @($exe, $OptionsPath, $manifestPath, $langPath, $generalPath, $modPath)

foreach ($path in $required) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Missing required file: $path. Locate the active game install and launch it once to create options.txt."
    }
}

$manifest = @(Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json)
if (-not ($manifest -contains 'zh_CN') -or ($manifest -contains 'en_US')) {
    throw "Unexpected vanilla_netease language manifest at $manifestPath. Inspect this version before patching."
}

function Read-Utf8File {
    param([string]$Path)
    $bytes = [IO.File]::ReadAllBytes($Path)
    $hasBom = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF
    $offset = if ($hasBom) { 3 } else { 0 }
    $utf8 = [Text.UTF8Encoding]::new($false, $true)
    [pscustomobject]@{
        Path = $Path
        Text = $utf8.GetString($bytes, $offset, $bytes.Length - $offset)
        HasBom = $hasBom
    }
}

function Replace-KeyLine {
    param([string]$Text, [string]$Key, [string]$Separator, [string]$Value)
    $prefix = "$Key$Separator"
    $pattern = '(?m)^' + [regex]::Escape($prefix) + '[^\r\n]*'
    $matches = [regex]::Matches($Text, $pattern)
    if ($matches.Count -ne 1) {
        throw "Expected exactly one '$prefix' line; found $($matches.Count). This version needs inspection."
    }
    $match = $matches[0]
    $replacement = "$prefix$Value"
    return $Text.Substring(0, $match.Index) + $replacement + $Text.Substring($match.Index + $match.Length)
}

function Replace-OneLiteral {
    param([string]$Text, [string]$Old, [string]$New)
    $oldCount = [regex]::Matches($Text, [regex]::Escape($Old)).Count
    $newCount = [regex]::Matches($Text, [regex]::Escape($New)).Count
    if ($oldCount -eq 1 -and $newCount -eq 0) { return $Text.Replace($Old, $New) }
    if ($oldCount -eq 0 -and $newCount -eq 1) { return $Text }
    throw "Expected exactly one old or new UI label ('$Old' / '$New'); found $oldCount / $newCount. Inspect this version."
}

$records = @{}
foreach ($path in @($OptionsPath, $langPath, $generalPath, $modPath)) {
    $records[$path] = Read-Utf8File -Path $path
}

$updated = @{}
$updated[$OptionsPath] = Replace-KeyLine -Text $records[$OptionsPath].Text -Key 'game_language' -Separator ':' -Value 'en_US'

$lang = $records[$langPath].Text
$translations = [ordered]@{
    'pause.generalSetting' = 'Mod Settings'
    'options.graphics_level' = 'Graphics Quality'
    'options.graphics_level.level1' = 'Performance'
    'options.graphics_level.level2' = 'Standard'
    'options.graphics_level.level3' = 'High'
    'options.graphics_level.recommend' = '(Recommended)'
    'options.graphics_level.self_define' = '(Custom)'
}
foreach ($key in $translations.Keys) {
    $lang = Replace-KeyLine -Text $lang -Key $key -Separator '=' -Value $translations[$key]
}
$updated[$langPath] = $lang

$general = Replace-OneLiteral -Text $records[$generalPath].Text -Old '"$option_label": "渲染引擎"' -New '"$option_label": "Rendering Engine"'
$null = $general | ConvertFrom-Json
$updated[$generalPath] = $general

$mod = Replace-OneLiteral -Text $records[$modPath].Text -Old '"text": "模组信息"' -New '"text": "Mod Information"'
$mod = Replace-OneLiteral -Text $mod -Old '"$place_holder_text": "请输入内容"' -New '"$place_holder_text": "Enter text"'
$null = $mod | ConvertFrom-Json
$updated[$modPath] = $mod

$changed = @($updated.Keys | Where-Object { $updated[$_] -cne $records[$_].Text })
if ($AuditOnly) {
    Write-Output "Validated NetEase resource structure. Files needing changes: $($changed.Count)"
    $changed | ForEach-Object { Write-Output $_ }
    return
}
if ($changed.Count -eq 0) {
    Write-Output 'Already configured. No files changed.'
    return
}
$runningTarget = @(Get-Process -Name 'Minecraft.Windows' -ErrorAction SilentlyContinue | Where-Object {
    try { $_.Path -and ([IO.Path]::GetFullPath($_.Path) -ieq [IO.Path]::GetFullPath($exe)) }
    catch { $false }
})
if ($runningTarget.Count -gt 0) {
    throw 'This Minecraft.Windows.exe is running. Exit the game completely before applying changes.'
}

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$suffix = [guid]::NewGuid().ToString('N').Substring(0, 6)
$backupDir = Join-Path $BackupRoot "$stamp-$suffix"
$null = New-Item -ItemType Directory -Path $backupDir -Force
foreach ($path in $records.Keys) {
    Copy-Item -LiteralPath $path -Destination (Join-Path $backupDir ([IO.Path]::GetFileName($path))) -Force
}

try {
    foreach ($path in $changed) {
        $encoding = [Text.UTF8Encoding]::new($records[$path].HasBom)
        [IO.File]::WriteAllText($path, $updated[$path], $encoding)
    }
} catch {
    foreach ($path in $records.Keys) {
        Copy-Item -LiteralPath (Join-Path $backupDir ([IO.Path]::GetFileName($path))) -Destination $path -Force
    }
    throw
}

Write-Output "Updated $($changed.Count) file(s). Backups: $backupDir"
Write-Output 'Restart the game and visually verify every requested screen.'
