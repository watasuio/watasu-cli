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

## App build billing

Deploying app source starts a paid build: **€0.50/hour**, billed per actual
running second with **8 vCPU and 15 GiB memory limits**. Failed or canceled builds
charge for the time they ran. Queue time and image-only pipeline promotions have
no build charge.

The app's billing account must have a positive available balance sufficient for
at least one second before manual, Git, connected GitHub, or pipeline source
builds start. Each build reserves up to €0.50 for at most one hour, or available
funds for a shorter deadline, and refunds unused funds after the builder stops.
No saved card is required; Stripe top-ups start at €5. See
[billing and limits](https://docs.watasu.io/admin/billing-and-limits/) for details.

## Release Metadata

- `latest.json` always points at the newest published release manifest.
- `manifests/vX.Y.Z.json` keeps version-pinned metadata for installers.

## Binary Releases

GitHub Releases in this repository carry the public archives and checksum file for each tagged CLI release.
