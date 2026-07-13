#Requires -Version 5.1
param(
    [string]$Version,
    [string]$InstallDir = "$env:LOCALAPPDATA\skarn"
)

$ErrorActionPreference = "Stop"
$RepoSlug = "skarn-security/skarn-dist"

function Get-SkarnAsset {
    param([string]$Tag)
    $arch = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture
    $assetName = switch ($arch) {
        "Arm64" { "skarn-aarch64-windows.exe" }
        "X64"   { "skarn-x86_64-windows.exe" }
        default { throw "skarn has no Windows build for OS architecture '$arch' (only X64 and Arm64 ship)." }
    }

    $releaseUrl = if ($Tag) {
        "https://api.github.com/repos/$RepoSlug/releases/tags/v$Tag"
    } else {
        "https://api.github.com/repos/$RepoSlug/releases/latest"
    }
    $release = Invoke-RestMethod -Uri $releaseUrl -Headers @{ "User-Agent" = "skarn-install.ps1" }
    $asset = $release.assets | Where-Object { $_.name -eq $assetName }
    if (-not $asset) {
        throw "release $($release.tag_name) has no asset named $assetName."
    }
    if (-not $asset.digest) {
        throw "release asset $assetName carries no GitHub-computed digest; refusing to install unverified."
    }
    [PSCustomObject]@{
        Tag             = $release.tag_name
        Url             = $asset.browser_download_url
        ExpectedSha256  = ($asset.digest -replace "^sha256:", "").ToLowerInvariant()
    }
}

function Install-Skarn {
    param([string]$Tag, [string]$Dir)

    Write-Host "Resolving the skarn release for this machine ($([System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture))..."
    $asset = Get-SkarnAsset -Tag $Tag
    Write-Host "Downloading skarn $($asset.Tag) from the public skarn-dist release..."

    $tempFile = Join-Path ([System.IO.Path]::GetTempPath()) "skarn-download-$(Get-Random).exe"
    try {
        Invoke-WebRequest -Uri $asset.Url -OutFile $tempFile -UseBasicParsing

        $actualSha256 = (Get-FileHash -Path $tempFile -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($actualSha256 -ne $asset.ExpectedSha256) {
            throw "checksum mismatch: expected $($asset.ExpectedSha256), got $actualSha256. Refusing to install a corrupted or tampered download."
        }
        Write-Host "sha256 verified: $actualSha256"

        New-Item -ItemType Directory -Force -Path $Dir | Out-Null
        $target = Join-Path $Dir "skarn.exe"
        Move-Item -Path $tempFile -Destination $target -Force
        Write-Host "Installed $target"
    }
    finally {
        if (Test-Path $tempFile) { Remove-Item $tempFile -Force }
    }

    $userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    if (($userPath -split ";") -notcontains $Dir) {
        [Environment]::SetEnvironmentVariable("PATH", "$userPath;$Dir", "User")
        Write-Host "Added $Dir to your user PATH. Open a new terminal for it to take effect."
    }
    if (($env:PATH -split ";") -notcontains $Dir) {
        $env:PATH = "$env:PATH;$Dir"
    }

    Write-Host ""
    Write-Host "Get started:"
    Write-Host "  1. Scan this machine:        skarn assess"
    Write-Host "  2. Install your license:     skarn license <path-to-your.skarnlicense>"
    Write-Host "  3. Wire the AI-agent guard:  skarn setup"
    Write-Host "  4. Verify it's working:      skarn doctor"
    Write-Host ""
    Write-Host "The core scan is free and needs no license."
}

Install-Skarn -Tag $Version -Dir $InstallDir
