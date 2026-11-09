#Requires -Version 5.1
param(
    [string]$Version,
    [string]$InstallDir = "$env:LOCALAPPDATA\skarn",
    [ValidateSet("auto", "require", "off")]
    [string]$VerifyProvenance = "auto"
)

$ErrorActionPreference = "Stop"
$RepoSlug = "skarn-security/skarn-dist"
$UserAgent = "skarn-install.ps1"
$SignerIdentityPrefix = '^https://github\.com/skarn-security/skarn/\.github/workflows/(release|publish-npm)\.yml@refs/tags/'
$UnverifiedConsequence = "the sha256 above still proves the download matches the release manifest, but nothing proves the Skarn release workflow produced those bytes"
$LegacyUnverifiedConsequence = "the sha256 above matches the digest GitHub recorded for that release asset, but nothing proves the Skarn release workflow produced those bytes"
$FirstSignedRelease = [System.Version]"0.19.0"

function Get-SkarnTagFromLatestUri {
    param([string]$Uri)
    if ($Uri -match '/releases/tag/(v[0-9][^/?#]*)') { return $Matches[1] }
    return ""
}

function Test-SkarnTagShape {
    param([string]$Tag)
    return $Tag -cmatch '^v[0-9]+\.[0-9]+\.[0-9]+$'
}

function Test-SkarnPreSignedRelease {
    param([string]$Tag, [System.Version]$FirstSigned)
    $parsed = $null
    if (-not [System.Version]::TryParse(($Tag -replace '^v', ''), [ref]$parsed)) { return $false }
    return $parsed -lt $FirstSigned
}

function Get-SkarnAssetName {
    param([string]$Arch)
    switch ($Arch) {
        "Arm64" { return "skarn-aarch64-windows.exe" }
        "X64"   { return "skarn-x86_64-windows.exe" }
    }
    throw "no Skarn Windows binary is published for architecture '$Arch'."
}

function Get-SkarnDownloadUrl {
    param([string]$Repo, [string]$Tag, [string]$Name)
    return "https://github.com/$Repo/releases/download/$Tag/$Name"
}

function Get-SkarnSumsEntry {
    param([string[]]$Lines, [string]$AssetName)
    foreach ($line in $Lines) {
        $fields = $line -split '\s+', 2
        if ($fields.Count -eq 2 -and $fields[1].Trim().TrimStart('*') -eq $AssetName) {
            return $fields[0].Trim().ToLowerInvariant()
        }
    }
    return ""
}

function Get-SkarnResponseUri {
    param($Response)
    $base = $Response.BaseResponse
    if ($null -eq $base) { return "" }
    $names = $base.PSObject.Properties.Name
    if ($names -contains "RequestMessage" -and $base.RequestMessage) {
        return [string]$base.RequestMessage.RequestUri
    }
    if ($names -contains "ResponseUri") {
        return [string]$base.ResponseUri
    }
    return ""
}

function Resolve-SkarnTag {
    param([string]$Version)
    if ($Version) {
        $pinned = "v" + ($Version -replace '^v', '')
        if (-not (Test-SkarnTagShape -Tag $pinned)) {
            throw "-Version must name a released version in X.Y.Z form, for example 0.21.0. Anything else is refused before a URL is built from it."
        }
        return $pinned
    }
    $latestUrl = "https://github.com/$RepoSlug/releases/latest"
    try {
        $response = Invoke-WebRequest -Uri $latestUrl -UseBasicParsing -Headers @{ "User-Agent" = $UserAgent }
    } catch {
        throw "could not resolve the latest Skarn release from $latestUrl ($($_.Exception.Message)). Pass -Version X.Y.Z to install a specific release."
    }
    $tag = Get-SkarnTagFromLatestUri -Uri (Get-SkarnResponseUri -Response $response)
    if (-not (Test-SkarnTagShape -Tag $tag)) {
        throw "could not read a released version in X.Y.Z form from the redirect at $latestUrl. Pass -Version X.Y.Z to install a specific release."
    }
    return $tag
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

function Get-SkarnSignedSums {
    param([string]$Tag, [string]$SumsPath, [string]$BundlePath)

    $base = "https://github.com/$RepoSlug/releases/download/$Tag"
    $manifestFetched = $false
    try {
        Invoke-WebRequest -Uri "$base/SHA256SUMS" -OutFile $SumsPath -UseBasicParsing
        $manifestFetched = $true
        Invoke-WebRequest -Uri "$base/SHA256SUMS.sigstore.json" -OutFile $BundlePath -UseBasicParsing
    } catch {
        $status = $null
        if ($_.Exception.Response) { $status = [int]$_.Exception.Response.StatusCode }
        if ($status -ne 404) {
            throw "could not fetch the signed SHA256SUMS for $Tag ($($_.Exception.Message)). This is a fetch failure, not a missing signature, so it is not treated as one. Re-run, or pass -Version to a release you know publishes one."
        }
        if ($manifestFetched) {
            throw "release $Tag publishes SHA256SUMS but no SHA256SUMS.sigstore.json to sign it. Every release that publishes one publishes both, so a manifest standing alone means the material this installer verifies against is incomplete, whether through tampering or a broken publication. Refusing to install; check the release at https://github.com/$RepoSlug/releases/tag/$Tag."
        }
        return $false
    }
    return $true
}

function Assert-SkarnSumsSignature {
    param([string]$Tag, [string]$SumsPath, [string]$BundlePath, [string]$Mode)

    if ($Mode -eq "off") {
        Write-Host "Provenance check off: $UnverifiedConsequence."
        return $false
    }

    if (-not (Get-Command cosign -ErrorAction SilentlyContinue)) {
        if ($Mode -eq "require") {
            throw "-VerifyProvenance require was set but cosign is not on PATH. Install it (winget install sigstore.cosign) and re-run, or drop -VerifyProvenance require."
        }
        Write-Warning "cosign is not on PATH, so $UnverifiedConsequence. Install cosign (winget install sigstore.cosign) and re-run to verify who built this binary."
        return $false
    }

    $identity = $SignerIdentityPrefix + [Regex]::Escape($Tag) + '$'
    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        & cosign verify-blob $SumsPath --bundle $BundlePath `
            --certificate-oidc-issuer "https://token.actions.githubusercontent.com" `
            --certificate-identity-regexp $identity | Out-Null
    }
    finally {
        $ErrorActionPreference = $previousPreference
    }
    if ($LASTEXITCODE -ne 0) {
        throw "SHA256SUMS for $Tag is not signed by the Skarn release workflow (expected a Sigstore keyless certificate identity matching $identity). Refusing to install: the checksums could have been substituted by anything with write access to the release."
    }
    return $true
}

function Get-SkarnLegacyDigest {
    param([string]$Tag, [string]$AssetName)

    $headers = @{ "User-Agent" = $UserAgent }
    $token = if ($env:GH_TOKEN) { $env:GH_TOKEN } elseif ($env:GITHUB_TOKEN) { $env:GITHUB_TOKEN } else { "" }
    if ($token) { $headers["Authorization"] = "Bearer $token" }

    try {
        $release = Invoke-RestMethod -Uri "https://api.github.com/repos/$RepoSlug/releases/tags/$Tag" -Headers $headers
    } catch {
        $status = $null
        if ($_.Exception.Response) { $status = [int]$_.Exception.Response.StatusCode }
        if ($status -eq 403 -or $status -eq 429) {
            throw "GitHub's API refused this request, which is almost always its unauthenticated limit of 60 requests per hour per IP address, shared by everyone behind your network address. Release $Tag predates the signed SHA256SUMS manifest, so its checksum can only come from that API. Install v0.19.0 or newer, which needs no API call at all, or set GH_TOKEN to a GitHub token and re-run."
        }
        throw "could not resolve release $Tag from the GitHub API ($($_.Exception.Message))."
    }

    $asset = $release.assets | Where-Object { $_.name -eq $AssetName }
    if (-not $asset) {
        throw "release $Tag has no asset named $AssetName."
    }
    if (-not $asset.digest) {
        throw "release asset $AssetName carries no GitHub-computed digest; refusing to install unverified."
    }
    return ($asset.digest -replace "^sha256:", "").ToLowerInvariant()
}

function Get-SkarnScopePath {
    param([string]$Scope)
    return [string][Environment]::GetEnvironmentVariable("PATH", $Scope)
}

function Set-SkarnUserPath {
    param([string]$Value)
    [Environment]::SetEnvironmentVariable("PATH", $Value, "User")
}

function Get-SkarnPathMatches {
    param([string]$MachinePath, [string]$UserPath, [string]$PathExt)
    $extensions = @(($PathExt -split ";") | Where-Object { $_.Trim() })
    if ($extensions.Count -eq 0) { $extensions = @(".COM", ".EXE", ".BAT", ".CMD") }
    $seen = New-Object "System.Collections.Generic.HashSet[string]" ([System.StringComparer]::OrdinalIgnoreCase)
    $found = New-Object "System.Collections.Generic.List[string]"
    foreach ($entry in ("$MachinePath;$UserPath" -split ";")) {
        $dir = [Environment]::ExpandEnvironmentVariables($entry.Trim().Trim('"'))
        if (-not $dir) { continue }
        foreach ($ext in $extensions) {
            try {
                $candidate = [System.IO.Path]::Combine($dir, "skarn" + $ext.Trim().ToLowerInvariant())
                if ([System.IO.File]::Exists($candidate)) {
                    $full = [System.IO.Path]::GetFullPath($candidate)
                    if ($seen.Add($full)) { $found.Add($full) }
                }
            } catch {
                continue
            }
        }
    }
    return $found.ToArray()
}

function Get-SkarnCandidateVersion {
    param([string]$Path, [int]$TimeoutMilliseconds = 5000)
    try {
        $start = New-Object System.Diagnostics.ProcessStartInfo
        $start.FileName = $Path
        $start.Arguments = "--version"
        $start.UseShellExecute = $false
        $start.CreateNoWindow = $true
        $start.RedirectStandardOutput = $true
        $start.RedirectStandardError = $true
        $process = [System.Diagnostics.Process]::Start($start)
        $stdout = $process.StandardOutput.ReadToEndAsync()
        $null = $process.StandardError.ReadToEndAsync()
        if (-not $process.WaitForExit($TimeoutMilliseconds)) {
            try { $process.Kill() } catch { $null = $_ }
            return "version unknown"
        }
        if ($process.ExitCode -eq 0 -and $stdout.Wait(1000) -and $stdout.Result -match '^skarn (\S+)') {
            return $Matches[1]
        }
    } catch {
        return "version unknown"
    }
    return "version unknown"
}

function Get-SkarnChannel {
    param([string]$Path, [string]$SystemRoot = $env:SystemRoot)
    $windowsPath = $Path -replace '/', '\'
    if ($SystemRoot -and $windowsPath.StartsWith($SystemRoot.TrimEnd('\') + '\', [System.StringComparison]::OrdinalIgnoreCase)) {
        $quoted = $Path -replace "'", "''"
        return "is in a Windows system folder. In PowerShell opened with Run as administrator, run: Remove-Item -LiteralPath '$quoted'"
    }
    if ($windowsPath -match '\\scoop\\(shims|apps\\skarn)\\') { return "was installed with Scoop. Run: scoop uninstall skarn" }
    if ($windowsPath -match '\\WinGet\\(Links|Packages)\\') { return "was installed with winget. Run: winget uninstall --id SkarnSecurity.Skarn --exact" }
    if ($windowsPath -match '\\AppData\\Roaming\\npm\\') { return "was installed with npm. Run: npm uninstall -g @skarn-security/skarn" }
    return "came from an installer this script does not recognise. Delete it if you no longer need it."
}

function Format-SkarnPathReport {
    param([string[]]$Found, [string]$Installed)
    $installedFull = [System.IO.Path]::GetFullPath($Installed)
    $installedAt = -1
    for ($i = 0; $i -lt $Found.Count; $i++) {
        if ([string]::Equals($Found[$i], $installedFull, [System.StringComparison]::OrdinalIgnoreCase)) {
            $installedAt = $i
            break
        }
    }
    if ($installedAt -eq 0) {
        return [pscustomobject]@{ Shadowed = $false; Lines = @("Typing skarn in a new terminal runs the copy just installed: $installedFull") }
    }
    if ($Found.Count -eq 0) {
        return [pscustomobject]@{ Shadowed = $true; Lines = @("A new terminal does not find skarn on your PATH. Run the copy just installed by its full path: $installedFull") }
    }
    $lines = New-Object "System.Collections.Generic.List[string]"
    $lines.Add("Typing skarn in a new terminal runs another copy, not the one just installed.")
    $lines.Add("Every skarn on your PATH, in the order Windows searches them:")
    for ($i = 0; $i -lt $Found.Count; $i++) {
        $note = ""
        if ($i -eq 0) { $note = " - runs when you type skarn" } elseif ($i -eq $installedAt) { $note = " - just installed" }
        $lines.Add("  $($i + 1). $($Found[$i]) ($(Get-SkarnCandidateVersion -Path $Found[$i]))$note")
    }
    $shadowing = $Found
    if ($installedAt -lt 0) {
        $lines.Add("The copy just installed, $installedFull, is not on your PATH.")
    } else {
        $shadowing = $Found[0..($installedAt - 1)]
    }
    $lines.Add("To run the new copy instead, remove each copy that comes before it:")
    foreach ($copy in $shadowing) {
        $lines.Add("  $copy $(Get-SkarnChannel -Path $copy)")
    }
    $lines.Add("This installer removed nothing. Until you remove them, run the new copy by its full path: $installedFull")
    return [pscustomobject]@{ Shadowed = $true; Lines = $lines.ToArray() }
}

function Install-Skarn {
    param([string]$Version, [string]$Dir)

    $arch = Get-SkarnOSArchitecture
    Write-Host "Resolving the skarn release for this machine ($arch)..."
    $tag = Resolve-SkarnTag -Version $Version
    $assetName = Get-SkarnAssetName -Arch $arch
    $assetUrl = Get-SkarnDownloadUrl -Repo $RepoSlug -Tag $tag -Name $assetName

    $temp = [System.IO.Path]::GetTempPath()
    $stamp = Get-Random
    $binary = Join-Path $temp "skarn-download-$stamp.exe"
    $sumsPath = Join-Path $temp "skarn-SHA256SUMS-$stamp"
    $bundlePath = "$sumsPath.sigstore.json"

    try {
        $haveSums = Get-SkarnSignedSums -Tag $tag -SumsPath $sumsPath -BundlePath $bundlePath

        Write-Host "Downloading skarn $tag from the public skarn-dist release..."
        try {
            Invoke-WebRequest -Uri $assetUrl -OutFile $binary -UseBasicParsing
        } catch {
            $status = $null
            if ($_.Exception.Response) { $status = [int]$_.Exception.Response.StatusCode }
            if ($status -eq 404) {
                throw "release $tag publishes no asset named $assetName at $assetUrl. Check the version you passed against https://github.com/$RepoSlug/releases."
            }
            throw "could not download $assetName for $tag ($($_.Exception.Message))."
        }

        $actualSha256 = (Get-FileHash -Path $binary -Algorithm SHA256).Hash.ToLowerInvariant()

        if ($haveSums) {
            $signed = Assert-SkarnSumsSignature -Tag $tag -SumsPath $sumsPath -BundlePath $bundlePath -Mode $VerifyProvenance
            $expected = Get-SkarnSumsEntry -Lines (Get-Content -Path $sumsPath) -AssetName $assetName
            if (-not $expected) {
                throw "the SHA256SUMS manifest for $tag has no entry for $assetName, so this download cannot be traced to the release manifest."
            }
            if ($actualSha256 -ne $expected) {
                throw "$assetName does not match the SHA256SUMS manifest for $tag (manifest says $expected, download is $actualSha256). Refusing to install."
            }
            Write-Host "sha256 verified: $actualSha256"
            if ($signed) {
                Write-Host "provenance verified: signed by the Skarn release workflow at $tag (Sigstore keyless)"
            }
        } else {
            if (-not (Test-SkarnPreSignedRelease -Tag $tag -FirstSigned $FirstSignedRelease)) {
                throw "release $tag publishes no SHA256SUMS manifest, and every release from v$FirstSignedRelease onward publishes one. Refusing to install: on a current release a missing manifest means the material this installer verifies against is absent, whether through tampering or a broken publication, and GitHub's own digest is no substitute because anything able to remove the manifest could rewrite that digest with it. Check the release at https://github.com/$RepoSlug/releases/tag/$tag."
            }
            if ($VerifyProvenance -eq "require") {
                throw "-VerifyProvenance require was set but release $tag publishes no signed SHA256SUMS; releases before v$FirstSignedRelease carry no signature. Install a newer version or drop -VerifyProvenance require."
            }
            $expected = Get-SkarnLegacyDigest -Tag $tag -AssetName $assetName
            if ($actualSha256 -ne $expected) {
                throw "checksum mismatch: expected $expected, got $actualSha256. Refusing to install a corrupted or tampered download."
            }
            Write-Host "sha256 verified: $actualSha256"
            Write-Warning "Release $tag predates the signed SHA256SUMS manifest, so $LegacyUnverifiedConsequence."
        }

        New-Item -ItemType Directory -Force -Path $Dir | Out-Null
        $target = Join-Path $Dir "skarn.exe"
        Move-Item -Path $binary -Destination $target -Force
        Write-Host "Installed $target"
    }
    finally {
        foreach ($f in @($binary, $sumsPath, $bundlePath)) {
            if (Test-Path $f) { Remove-Item $f -Force }
        }
    }

    $userPath = Get-SkarnScopePath -Scope User
    if (($userPath -split ";") -notcontains $Dir) {
        Set-SkarnUserPath -Value "$userPath;$Dir"
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

    $found = @(Get-SkarnPathMatches -MachinePath (Get-SkarnScopePath -Scope Machine) -UserPath (Get-SkarnScopePath -Scope User) -PathExt $env:PATHEXT)
    $report = Format-SkarnPathReport -Found $found -Installed $target
    Write-Host ""
    if ($report.Shadowed) {
        Write-Warning $report.Lines[0]
        $report.Lines | Select-Object -Skip 1 | ForEach-Object { Write-Host $_ }
    } else {
        Write-Host $report.Lines[0]
    }
}

Install-Skarn -Version $Version -Dir $InstallDir
