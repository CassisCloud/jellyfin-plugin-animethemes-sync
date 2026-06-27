<#
.SYNOPSIS
    Updates the UI asset and display version across the codebase.
.DESCRIPTION
    If no new version is specified, it automatically increments the current version from Constants.cs.
    If the current version's date is today, the daily suffix letter (e.g. 'd' -> 'e') is incremented.
    Otherwise, a new version for today's date with suffix 'a' (e.g. '20260627a') is generated.
.PARAMETER Version
    Optional custom version to set. E.g. '20260627e' or '2026.06.27-e'.
    The script will automatically normalize both Asset and Display formats.
#>
param(
    [string]$Version
)

$ErrorActionPreference = "Stop"

# Paths
$repoRoot = $PSScriptRoot
$constantsPath = Join-Path $repoRoot "AnimeThemesSync.Shared/Constants.cs"
$jfConfigPage = Join-Path $repoRoot "Jellyfin.Plugin.AnimeThemesSync/Configuration/configPage.html"
$jfBrowserPage = Join-Path $repoRoot "Jellyfin.Plugin.AnimeThemesSync/Configuration/browserPage.html"
$embyConfigPage = Join-Path $repoRoot "Emby.Plugin.AnimeThemesSync/Configuration/configPage.html"
$embyBrowserPage = Join-Path $repoRoot "Emby.Plugin.AnimeThemesSync/Configuration/browserPage.html"

# 1. Read current version from Constants.cs
if (-not (Test-Path $constantsPath)) {
    throw "Constants.cs not found at $constantsPath"
}
$constantsContent = Get-Content $constantsPath -Raw

if ($constantsContent -match 'public const string UiAssetVersion = "([^"]+)";') {
    $currentAssetVersion = $Matches[1]
} else {
    throw "Could not parse UiAssetVersion from Constants.cs"
}

if ($constantsContent -match 'public const string UiDisplayVersion = "([^"]+)";') {
    $currentDisplayVersion = $Matches[1]
} else {
    throw "Could not parse UiDisplayVersion from Constants.cs"
}

Write-Host "Current UI Asset Version:   $currentAssetVersion"
Write-Host "Current UI Display Version: $currentDisplayVersion"

# 2. Determine new version
$newAssetVersion = ""
$newDisplayVersion = ""

if (-not [string]::IsNullOrWhiteSpace($Version)) {
    # Normalize custom version input
    # Expected format: either 20260627e or 2026.06.27-e
    if ($Version -match '^(\d{4})\.?(\d{2})\.?(\d{2})[-_]?([a-z])$') {
        $year = $Matches[1]
        $month = $Matches[2]
        $day = $Matches[3]
        $suffix = $Matches[4]
        $newAssetVersion = "$year$month$day$suffix"
        $newDisplayVersion = "$year.$month.$day-$suffix"
    } else {
        throw "Invalid version format '$Version'. Expected format like '20260627e' or '2026.06.27-e'."
    }
} else {
    # Auto-increment
    $today = Get-Date -Format "yyyyMMdd"
    # Parse current asset version
    if ($currentAssetVersion -match '^(\d{8})([a-z])$') {
        $currentDatePart = $Matches[1]
        $currentSuffixPart = $Matches[2]
        
        if ($currentDatePart -eq $today) {
            # Increment suffix
            $nextChar = [char]([int][char]$currentSuffixPart + 1)
            $newAssetVersion = "$today$nextChar"
        } else {
            # Reset suffix to 'a' for a new day
            $newAssetVersion = "${today}a"
        }
    } else {
        # Fallback if current version is not in expected format
        $newAssetVersion = "${today}a"
    }
    
    # Form display version (e.g. 20260627e -> 2026.06.27-e)
    if ($newAssetVersion -match '^(\d{4})(\d{2})(\d{2})([a-z])$') {
        $newDisplayVersion = "$($Matches[1]).$($Matches[2]).$($Matches[3])-$($Matches[4])"
    } else {
        throw "Failed to generate new display version from '$newAssetVersion'"
    }
}

Write-Host "Target UI Asset Version:    $newAssetVersion" -ForegroundColor Green
Write-Host "Target UI Display Version:  $newDisplayVersion" -ForegroundColor Green

# 3. Perform replacements

# A. Constants.cs
Write-Host "Updating Constants.cs..."
$newConstants = $constantsContent -replace 'public const string UiAssetVersion = "[^"]+";', "public const string UiAssetVersion = `"$newAssetVersion`";"
$newConstants = $newConstants -replace 'public const string UiDisplayVersion = "[^"]+";', "public const string UiDisplayVersion = `"$newDisplayVersion`";"
Set-Content $constantsPath $newConstants -NoNewline

# B. Jellyfin configPage.html
if (Test-Path $jfConfigPage) {
    Write-Host "Updating Jellyfin configPage.html..."
    $content = Get-Content $jfConfigPage -Raw
    $newContent = $content -replace 'animethemessyncbrowser[a-zA-Z0-9]+', "animethemessyncbrowser$newAssetVersion"
    Set-Content $jfConfigPage $newContent -NoNewline
}

# C. Jellyfin browserPage.html
if (Test-Path $jfBrowserPage) {
    Write-Host "Updating Jellyfin browserPage.html..."
    $content = Get-Content $jfBrowserPage -Raw
    $newContent = $content -replace 'UI version: [^<]*', "UI version: $newDisplayVersion."
    Set-Content $jfBrowserPage $newContent -NoNewline
}

# D. Emby configPage.html
if (Test-Path $embyConfigPage) {
    Write-Host "Updating Emby configPage.html..."
    $content = Get-Content $embyConfigPage -Raw
    $newContent = $content -replace 'animethemessyncconfigjs[a-zA-Z0-9]+', "animethemessyncconfigjs$newAssetVersion"
    $newContent = $newContent -replace 'animethemessyncbrowser[a-zA-Z0-9]+', "animethemessyncbrowser$newAssetVersion"
    Set-Content $embyConfigPage $newContent -NoNewline
}

# E. Emby browserPage.html
if (Test-Path $embyBrowserPage) {
    Write-Host "Updating Emby browserPage.html..."
    $content = Get-Content $embyBrowserPage -Raw
    $newContent = $content -replace 'animethemessyncbrowserjs[a-zA-Z0-9]+', "animethemessyncbrowserjs$newAssetVersion"
    $newContent = $newContent -replace 'UI version: [^<]*', "UI version: $newDisplayVersion."
    Set-Content $embyBrowserPage $newContent -NoNewline
}

Write-Host "UI Asset Version updated successfully to $newAssetVersion ($newDisplayVersion)." -ForegroundColor Green
