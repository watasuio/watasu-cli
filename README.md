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

Install from the official Watasu tap:

```bash
brew install watasuio/watasu/watasu
```

The fully qualified name trusts only the Watasu formula. See
[Homebrew tap trust](https://docs.brew.sh/Tap-Trust) and the
[formula source](https://github.com/watasuio/homebrew-watasu/blob/main/Formula/watasu.rb).

Update with `brew upgrade watasuio/watasu/watasu`. If an existing installation
reports the formula as untrusted, run `brew trust --formula watasuio/watasu/watasu`
and retry the upgrade.

## Release Metadata

- `latest.json` always points at the newest published release manifest.
- `manifests/vX.Y.Z.json` keeps version-pinned metadata for installers.

## Binary Releases

GitHub Releases in this repository carry the public archives and checksum file for each tagged CLI release.
