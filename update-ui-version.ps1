<#
.SYNOPSIS
    Advances the date-based UI cache and display version used during development.
#>
param(
    [string]$Version
)

$ErrorActionPreference = "Stop"
$repoRoot = $PSScriptRoot
$constantsPath = Join-Path $repoRoot "AnimeThemesSync.Shared/Constants.cs"
$jfConfigPage = Join-Path $repoRoot "Jellyfin.Plugin.AnimeThemesSync/Configuration/configPage.html"
$jfBrowserPage = Join-Path $repoRoot "Jellyfin.Plugin.AnimeThemesSync/Configuration/browserPage.html"
$embyConfigPage = Join-Path $repoRoot "Emby.Plugin.AnimeThemesSync/Configuration/configPage.html"
$embyBrowserPage = Join-Path $repoRoot "Emby.Plugin.AnimeThemesSync/Configuration/browserPage.html"

$constantsContent = Get-Content $constantsPath -Raw
if ($constantsContent -notmatch 'public const string UiAssetVersion = "([^"]+)";') {
    throw "Could not parse UiAssetVersion from Constants.cs."
}

$currentAssetVersion = $Matches[1]
if ([string]::IsNullOrWhiteSpace($Version)) {
    $today = Get-Date -Format "yyyyMMdd"
    if ($currentAssetVersion -match '^(\d{8})([a-z])$' -and $Matches[1] -eq $today) {
        $assetVersion = $today + [char]([int][char]$Matches[2] + 1)
    }
    else {
        $assetVersion = $today + "a"
    }
}
else {
    if ($Version -notmatch '^(\d{4})\.?(\d{2})\.?(\d{2})[-_]?([a-z])$') {
        throw "Invalid debug UI version '$Version'. Expected 20260629c or 2026.06.29-c."
    }

    $assetVersion = "$($Matches[1])$($Matches[2])$($Matches[3])$($Matches[4])"
}

if ($assetVersion -notmatch '^(\d{4})(\d{2})(\d{2})([a-z])$') {
    throw "Could not create a display version from '$assetVersion'."
}

$displayVersion = "$($Matches[1]).$($Matches[2]).$($Matches[3])-$($Matches[4])"
$constantsContent = $constantsContent -replace 'public const string UiAssetVersion = "[^"]+";', ('public const string UiAssetVersion = "{0}";' -f $assetVersion)
Set-Content $constantsPath $constantsContent -NoNewline

$jfConfig = Get-Content $jfConfigPage -Raw
$jfConfig = $jfConfig -replace 'animethemessyncbrowser[a-zA-Z0-9.]+', ("animethemessyncbrowser" + $assetVersion)
Set-Content $jfConfigPage $jfConfig -NoNewline

$jfBrowser = Get-Content $jfBrowserPage -Raw
$jfBrowser = $jfBrowser -replace '<div class="fieldDescription">(?:UI version|Version):[^<]*</div>', ('<div class="fieldDescription">UI version: {0}.</div>' -f $displayVersion)
Set-Content $jfBrowserPage $jfBrowser -NoNewline

$embyConfig = Get-Content $embyConfigPage -Raw
$embyConfig = $embyConfig -replace 'animethemessyncconfigjs[a-zA-Z0-9.]+', ("animethemessyncconfigjs" + $assetVersion)
$embyConfig = $embyConfig -replace 'animethemessyncbrowser[a-zA-Z0-9.]+', ("animethemessyncbrowser" + $assetVersion)
Set-Content $embyConfigPage $embyConfig -NoNewline

$embyBrowser = Get-Content $embyBrowserPage -Raw
$embyBrowser = $embyBrowser -replace 'animethemessyncbrowserjs[a-zA-Z0-9.]+', ("animethemessyncbrowserjs" + $assetVersion)
$embyBrowser = $embyBrowser -replace '<div class="fieldDescription">(?:UI version|Version):[^<]*</div>', ('<div class="fieldDescription">UI version: {0}.</div>' -f $displayVersion)
Set-Content $embyBrowserPage $embyBrowser -NoNewline

Write-Host "Debug UI version updated to $displayVersion ($assetVersion)." -ForegroundColor Green
