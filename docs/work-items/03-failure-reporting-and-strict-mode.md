# 03 Failure Reporting And Strict Mode

Status: `ready`

Suggested branch: `feat/linuxbrew-failure-reporting`

## Goal

Improve observability around partial failures and add an opt-in mode that fails
hard when package operations fail.

## Scope

- collect failures and print a final summary
- add a stable log prefix such as `[nix-linuxbrew]`
- add an opt-in strict mode like `failOnPackageError`

## Validation

- partial failures are easier to spot in logs
- strict mode exits non-zero when intended
