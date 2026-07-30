#Requires -Version 5.1
param(
    [string]$Version,
    [string]$InstallDir = "$env:LOCALAPPDATA\skarn",
    [ValidateSet("auto", "require", "off")]
    [string]$VerifyProvenance = "auto"
)

$ErrorActionPreference = "Stop"
$RepoSlug = "skarn-security/skarn-dist"
$SignerIdentityPrefix = '^https://github\.com/skarn-security/skarn/\.github/workflows/(release|publish-npm)\.yml@refs/tags/'
$UnverifiedConsequence = "the sha256 above still proves the download matches what GitHub recorded, but nothing proves the Skarn release workflow produced those bytes"

function Assert-SkarnProvenance {
    param([string]$Tag, [string]$AssetName, [string]$FilePath, [string]$Mode)

    if ($Mode -eq "off") {
        Write-Host "Provenance check off: $UnverifiedConsequence."
        return
    }

    $base = "https://github.com/$RepoSlug/releases/download/$Tag"
    $sums = Join-Path ([System.IO.Path]::GetTempPath()) "skarn-SHA256SUMS-$(Get-Random)"
    $bundle = "$sums.sigstore.json"
    try {
        try {
            Invoke-WebRequest -Uri "$base/SHA256SUMS" -OutFile $sums -UseBasicParsing
            Invoke-WebRequest -Uri "$base/SHA256SUMS.sigstore.json" -OutFile $bundle -UseBasicParsing
        } catch {
            $status = $null
            if ($_.Exception.Response) { $status = [int]$_.Exception.Response.StatusCode }
            if ($status -ne 404) {
                throw "could not fetch the signed SHA256SUMS for $Tag ($($_.Exception.Message)). This is a fetch failure, not a missing signature, so it is not treated as one. Re-run, or pass -VerifyProvenance off to install without checking provenance."
            }
            if ($Mode -eq "require") {
                throw "-VerifyProvenance require was set but release $Tag publishes no signed SHA256SUMS; releases before v0.19.0 carry no signature. Install a newer version or drop -VerifyProvenance require."
            }
            Write-Warning "Release $Tag publishes no signed SHA256SUMS, so $UnverifiedConsequence."
            return
        }

        if (-not (Get-Command cosign -ErrorAction SilentlyContinue)) {
            if ($Mode -eq "require") {
                throw "-VerifyProvenance require was set but cosign is not on PATH. Install it (winget install sigstore.cosign) and re-run, or drop -VerifyProvenance require."
            }
            Write-Warning "cosign is not on PATH, so $UnverifiedConsequence. Install cosign (winget install sigstore.cosign) and re-run to verify who built this binary."
            return
        }

        $identity = $SignerIdentityPrefix + [Regex]::Escape($Tag) + '$'
        $previousPreference = $ErrorActionPreference
        $ErrorActionPreference = "Continue"
        try {
            & cosign verify-blob $sums --bundle $bundle `
                --certificate-oidc-issuer "https://token.actions.githubusercontent.com" `
                --certificate-identity-regexp $identity | Out-Null
        }
        finally {
            $ErrorActionPreference = $previousPreference
        }
        if ($LASTEXITCODE -ne 0) {
            throw "SHA256SUMS for $Tag is not signed by the Skarn release workflow (expected a Sigstore keyless certificate identity matching $identity). Refusing to install: the checksums could have been substituted by anything with write access to the release."
        }

        $expected = ""
        foreach ($line in Get-Content -Path $sums) {
            $fields = $line -split '\s+', 2
            if ($fields.Count -eq 2 -and $fields[1].Trim() -eq $AssetName) {
                $expected = $fields[0].Trim().ToLowerInvariant()
                break
            }
        }
        if (-not $expected) {
            throw "the signed SHA256SUMS for $Tag has no entry for $AssetName, so this download cannot be traced to the signed release manifest."
        }
        $actual = (Get-FileHash -Path $FilePath -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($actual -ne $expected) {
            throw "$AssetName does not match the signed SHA256SUMS for $Tag (signed manifest says $expected, download is $actual). Refusing to install."
        }
        Write-Host "provenance verified: signed by the Skarn release workflow at $Tag (Sigstore keyless)"
    }
    finally {
        foreach ($f in @($sums, $bundle)) {
            if (Test-Path $f) { Remove-Item $f -Force }
        }
    }
}

function Get-SkarnRuntimeArchitecture {
    try {
        return [string][System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture
    } catch {
        return ""
    }
}

function Get-SkarnOSArchitecture {
    $probes = [ordered]@{}
    $probes["RuntimeInformation.OSArchitecture"] = Get-SkarnRuntimeArchitecture
    $probes["PROCESSOR_ARCHITEW6432"] = [string]$env:PROCESSOR_ARCHITEW6432
    $probes["PROCESSOR_ARCHITECTURE"] = [string]$env:PROCESSOR_ARCHITECTURE

    foreach ($probe in $probes.GetEnumerator()) {
        switch -Regex ($probe.Value) {
            '^(arm64|aarch64)$' { return "Arm64" }
            '^(amd64|x64)$'     { return "X64" }
        }
    }

    $detail = ($probes.GetEnumerator() | ForEach-Object { "$($_.Key)='$($_.Value)'" }) -join "; "
    throw "skarn could not determine this machine's Windows architecture (only X64 and Arm64 ship). Probed: $detail. Report this with the probe values at https://github.com/skarn-security/skarn-dist/issues"
}

function Get-SkarnAsset {
    param([string]$Arch, [string]$Tag)
    $assetName = switch ($Arch) {
        "Arm64" { "skarn-aarch64-windows.exe" }
        "X64"   { "skarn-x86_64-windows.exe" }
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
        Name            = $assetName
        Url             = $asset.browser_download_url
        ExpectedSha256  = ($asset.digest -replace "^sha256:", "").ToLowerInvariant()
    }
}

function Install-Skarn {
    param([string]$Tag, [string]$Dir)

    $arch = Get-SkarnOSArchitecture
    Write-Host "Resolving the skarn release for this machine ($arch)..."
    $asset = Get-SkarnAsset -Arch $arch -Tag $Tag
    Write-Host "Downloading skarn $($asset.Tag) from the public skarn-dist release..."

    $tempFile = Join-Path ([System.IO.Path]::GetTempPath()) "skarn-download-$(Get-Random).exe"
    try {
        Invoke-WebRequest -Uri $asset.Url -OutFile $tempFile -UseBasicParsing

        $actualSha256 = (Get-FileHash -Path $tempFile -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($actualSha256 -ne $asset.ExpectedSha256) {
            throw "checksum mismatch: expected $($asset.ExpectedSha256), got $actualSha256. Refusing to install a corrupted or tampered download."
        }
        Write-Host "sha256 verified: $actualSha256"

        Assert-SkarnProvenance -Tag $asset.Tag -AssetName $asset.Name -FilePath $tempFile -Mode $VerifyProvenance

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
    Write-Host "skarn assess needs no license. skarn check scans need the free license from https://getskarn.com/free"
}

Install-Skarn -Tag $Version -Dir $InstallDir
