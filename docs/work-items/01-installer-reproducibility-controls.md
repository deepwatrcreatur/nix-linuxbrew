# 01 Installer Reproducibility Controls

Status: `ready`

Suggested branch: `feat/linuxbrew-installer-reproducibility`

## Goal

Reduce non-determinism and supply-chain risk in the Homebrew installer path by
making the installer source explicit and optionally verifiable.

## Scope

- add installer source modes such as `upstream-head`, `pinned-url`, and `local-file`
- support optional hash verification for remote installer sources
- document a fully pinned setup pattern

## Validation

- module evaluation still works with the current default behavior
- pinned modes fail clearly when configuration is incomplete or invalid
