param(
  [string]$Version = "latest"
)

$ErrorActionPreference = "Stop"

if ([System.Environment]::OSVersion.Platform -ne [System.PlatformID]::Win32NT) {
  throw "install.ps1 only supports Windows. Use install.sh on macOS, Linux, or WSL."
}

if ($Version -notmatch '^(latest|v?\d+\.\d+\.\d+([-.][0-9A-Za-z.]+)?)$') {
  throw "Usage: install.ps1 [latest|VERSION]"
}

$BaseUrl = if ($env:WATASU_INSTALL_BASE_URL) { $env:WATASU_INSTALL_BASE_URL.TrimEnd("/") } else { "https://watasuio.github.io/watasu-cli" }
$InstallDir = if ($env:WATASU_INSTALL_DIR) { $env:WATASU_INSTALL_DIR } else { Join-Path $env:LOCALAPPDATA "Programs\Watasu\bin" }

$platform = switch ([System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture) {
  "X64" { "windows-amd64" }
  default { throw "Unsupported Windows architecture: $([System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture)" }
}

if ($Version -eq "latest") {
  $manifestUrl = "$BaseUrl/latest.json"
} else {
  if (-not $Version.StartsWith("v")) {
    $Version = "v$Version"
  }
  $manifestUrl = "$BaseUrl/manifests/$Version.json"
}

$manifest = Invoke-RestMethod -Uri $manifestUrl
$assetProperty = $manifest.platforms.PSObject.Properties[$platform]

if (-not $assetProperty) {
  throw "Platform $platform is not available in $manifestUrl"
}

$asset = $assetProperty.Value

$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("watasu-install-" + [guid]::NewGuid().ToString("N"))
$archivePath = Join-Path $tempRoot $asset.asset
$extractDir = Join-Path $tempRoot "extract"

New-Item -ItemType Directory -Force -Path $tempRoot | Out-Null
New-Item -ItemType Directory -Force -Path $extractDir | Out-Null

try {
  Invoke-WebRequest -Uri $asset.url -OutFile $archivePath

  $actualChecksum = (Get-FileHash -Path $archivePath -Algorithm SHA256).Hash.ToLowerInvariant()
  if ($actualChecksum -ne $asset.checksum.ToLowerInvariant()) {
    throw "Checksum verification failed"
  }

  switch ($asset.archive) {
    "zip" {
      Expand-Archive -LiteralPath $archivePath -DestinationPath $extractDir -Force
    }
    default {
      throw "Unsupported archive format: $($asset.archive)"
    }
  }

  $binary = Get-ChildItem -Path $extractDir -Filter "watasu.exe" -File -Recurse | Select-Object -First 1
  if (-not $binary) {
    throw "Could not find watasu.exe in the downloaded archive"
  }

  New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
  Copy-Item -LiteralPath $binary.FullName -Destination (Join-Path $InstallDir "watasu.exe") -Force

  $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
  $pathEntries = @()
  if (-not [string]::IsNullOrWhiteSpace($userPath)) {
    $pathEntries = $userPath.Split(";", [System.StringSplitOptions]::RemoveEmptyEntries)
  }

  if (-not ($pathEntries -contains $InstallDir)) {
    $newUserPath = if ([string]::IsNullOrWhiteSpace($userPath)) { $InstallDir } else { "$userPath;$InstallDir" }
    [Environment]::SetEnvironmentVariable("Path", $newUserPath, "User")
    Write-Host "Added $InstallDir to your user PATH. Open a new terminal to pick it up."
  }

  Write-Host "Installed watasu $($manifest.version) to $(Join-Path $InstallDir 'watasu.exe')"
}
finally {
  if (Test-Path $tempRoot) {
    Remove-Item -LiteralPath $tempRoot -Recurse -Force
  }
}
