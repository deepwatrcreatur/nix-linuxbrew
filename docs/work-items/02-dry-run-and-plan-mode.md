# 02 Dry Run And Plan Mode

Status: `ready`

Suggested branch: `feat/linuxbrew-dry-run-plan-mode`

## Goal

Add a plan mode that prints the exact `brew` operations that would run during
activation without mutating state.

## Scope

- add `programs.linuxbrew.dryRun`
- print tap/install/link/compiler commands in dry-run mode
- consider exposing a reusable `--plan` path outside activation

## Validation

- dry-run output is readable and stable
- normal activation behavior is unchanged when dry-run is disabled
