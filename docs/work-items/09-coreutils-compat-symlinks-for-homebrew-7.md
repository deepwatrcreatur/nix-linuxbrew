# 09 Coreutils Compatibility Symlinks for Homebrew 7.0+

Status: `done`

Branch: `main` (commit `9df0591ed76fed4d0cc9ed20fc311a7ef72aea1f`)

## Goal

Ensure Homebrew 7.0+ internal shell commands (such as `brew update`) execute cleanly on NixOS without missing utility errors.

## Context & Rationale

Homebrew 7.0's `Library/Homebrew/cmd/update.sh` invokes commands like `wc -c`, `tr`, `curl`, and `git` under a sanitized `PATH="/usr/bin:/bin:/usr/sbin:/sbin"`. On standard NixOS, `/bin` and `/usr/bin` do not provide `wc` or `tr` by default. Prior configurations lacked these symlinks in default `compatSymlinks`, causing `brew update` to fail silently with:
`/home/linuxbrew/.linuxbrew/Homebrew/Library/Homebrew/cmd/update.sh: line 438: wc: command not found`

## Scope

- In `modules/nixos-linuxbrew.nix`, expand default `compatSymlinks` to include:
  - `${pkgs.coreutils}/bin/tr` -> `/bin/tr` and `/usr/bin/tr`
  - `${pkgs.coreutils}/bin/wc` -> `/bin/wc` and `/usr/bin/wc`
  - `${pkgs.curl}/bin/curl` -> `/bin/curl` and `/usr/bin/curl`
  - `${pkgs.git}/bin/git` -> `/bin/git` and `/usr/bin/git`

## Outcome

- Merged in commit `9df0591`. `brew update` and Homebrew 7.0 operations succeed on NixOS hosts without requiring ad-hoc downstream overrides.
