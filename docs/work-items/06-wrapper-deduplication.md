# 06 Wrapper Deduplication

Status: `ready`

Suggested branch: `refactor/linuxbrew-wrapper-dedup`

## Goal

Reduce duplication between `brew-wrapper` logic in the flake package path and
the module implementation.

## Scope

- extract shared wrapper construction into one helper
- reuse it from both the flake package and module path

## Validation

- wrapper behavior stays functionally consistent
- duplicated logic meaningfully shrinks
