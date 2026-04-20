# Watasu CLI

Install the `watasu` command-line tool for macOS, Linux, WSL, or Windows.

Use `watasu` to log in, manage apps, and work with Watasu from your terminal. This repository hosts the public installers, release files, and update metadata for the CLI.

## Install

macOS / Linux / WSL:

```bash
curl -fsSL https://watasuio.github.io/watasu-cli/install.sh | bash
```

Windows PowerShell:

```powershell
irm https://watasuio.github.io/watasu-cli/install.ps1 | iex
```

## Homebrew

The Homebrew tap lives in the dedicated public repository `watasuio/homebrew-watasu`, so users get the short tap command:

```bash
brew tap watasuio/watasu
brew install watasu
```

The formula source is published to `https://github.com/watasuio/homebrew-watasu`.

## Release Metadata

- `latest.json` always points at the newest published release manifest.
- `manifests/vX.Y.Z.json` keeps version-pinned metadata for installers.

## Binary Releases

GitHub Releases in this repository carry the public archives and checksum file for each tagged CLI release.
