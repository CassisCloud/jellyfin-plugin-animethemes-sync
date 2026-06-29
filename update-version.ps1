<#
.SYNOPSIS
    Synchronizes the plugin release version across build metadata and UI assets.
.PARAMETER Version
    Semantic release version such as 2.3.1. When omitted, build.yaml is used.
#>
param(
    [string]$Version
)

$ErrorActionPreference = "Stop"
$repoRoot = $PSScriptRoot
$buildPath = Join-Path $repoRoot "build.yaml"
$propsPath = Join-Path $repoRoot "Directory.Build.props"
$constantsPath = Join-Path $repoRoot "AnimeThemesSync.Shared/Constants.cs"
$jfConfigPage = Join-Path $repoRoot "Jellyfin.Plugin.AnimeThemesSync/Configuration/configPage.html"
$jfBrowserPage = Join-Path $repoRoot "Jellyfin.Plugin.AnimeThemesSync/Configuration/browserPage.html"
$embyConfigPage = Join-Path $repoRoot "Emby.Plugin.AnimeThemesSync/Configuration/configPage.html"
$embyBrowserPage = Join-Path $repoRoot "Emby.Plugin.AnimeThemesSync/Configuration/browserPage.html"

if ([string]::IsNullOrWhiteSpace($Version)) {
    $buildContent = Get-Content $buildPath -Raw
    if ($buildContent -notmatch '(?m)^version:\s*["'']?([^"''\r\n]+)') {
        throw "Could not read the version from build.yaml."
    }

    $Version = $Matches[1].Trim()
}

$normalizedVersion = $Version.Trim().TrimStart('v')
if ($normalizedVersion -notmatch '^(\d+)\.(\d+)\.(\d+)$') {
    throw "Invalid release version '$Version'. Expected X.Y.Z, for example 2.3.1."
}

$assemblyVersion = "$($Matches[1]).$($Matches[2]).$($Matches[3]).0"
$assetVersion = "v" + ($normalizedVersion -replace '[^0-9A-Za-z]', '')
Write-Host "Synchronizing release version $normalizedVersion (UI asset suffix $assetVersion)..."

$buildContent = Get-Content $buildPath -Raw
$buildContent = $buildContent -replace '(?m)^version:\s*["'']?[^"''\r\n]+["'']?', ('version: "{0}"' -f $normalizedVersion)
Set-Content $buildPath $buildContent -NoNewline

$propsContent = Get-Content $propsPath -Raw
$propsContent = $propsContent -replace '<Version Condition="''\$\(Version\)'' == ''''">[^<]+</Version>', ('<Version Condition="''$(Version)'' == ''''">{0}</Version>' -f $normalizedVersion)
$propsContent = $propsContent -replace '<AssemblyVersion Condition="''\$\(AssemblyVersion\)'' == ''''">[^<]+</AssemblyVersion>', ('<AssemblyVersion Condition="''$(AssemblyVersion)'' == ''''">{0}</AssemblyVersion>' -f $assemblyVersion)
$propsContent = $propsContent -replace '<FileVersion Condition="''\$\(FileVersion\)'' == ''''">[^<]+</FileVersion>', ('<FileVersion Condition="''$(FileVersion)'' == ''''">{0}</FileVersion>' -f $assemblyVersion)
Set-Content $propsPath $propsContent -NoNewline

$constantsContent = Get-Content $constantsPath -Raw
$constantsContent = $constantsContent -replace 'public const string UiAssetVersion = "[^"]+";', ('public const string UiAssetVersion = "{0}";' -f $assetVersion)
$constantsContent = $constantsContent -replace 'public const string PluginVersion = "[^"]+";', ('public const string PluginVersion = "{0}";' -f $normalizedVersion)
Set-Content $constantsPath $constantsContent -NoNewline

$jfConfig = Get-Content $jfConfigPage -Raw
$jfConfig = $jfConfig -replace 'animethemessyncbrowser[a-zA-Z0-9.]+', ("animethemessyncbrowser" + $assetVersion)
Set-Content $jfConfigPage $jfConfig -NoNewline

$jfBrowser = Get-Content $jfBrowserPage -Raw
$jfBrowser = $jfBrowser -replace '<div class="fieldDescription">(?:UI version|Version):[^<]*</div>', ('<div class="fieldDescription">Version: {0}.</div>' -f $normalizedVersion)
Set-Content $jfBrowserPage $jfBrowser -NoNewline

$embyConfig = Get-Content $embyConfigPage -Raw
$embyConfig = $embyConfig -replace 'animethemessyncconfigjs[a-zA-Z0-9.]+', ("animethemessyncconfigjs" + $assetVersion)
$embyConfig = $embyConfig -replace 'animethemessyncbrowser[a-zA-Z0-9.]+', ("animethemessyncbrowser" + $assetVersion)
Set-Content $embyConfigPage $embyConfig -NoNewline

$embyBrowser = Get-Content $embyBrowserPage -Raw
$embyBrowser = $embyBrowser -replace 'animethemessyncbrowserjs[a-zA-Z0-9.]+', ("animethemessyncbrowserjs" + $assetVersion)
$embyBrowser = $embyBrowser -replace '<div class="fieldDescription">(?:UI version|Version):[^<]*</div>', ('<div class="fieldDescription">Version: {0}.</div>' -f $normalizedVersion)
Set-Content $embyBrowserPage $embyBrowser -NoNewline

Write-Host "Release version synchronization complete." -ForegroundColor Green
