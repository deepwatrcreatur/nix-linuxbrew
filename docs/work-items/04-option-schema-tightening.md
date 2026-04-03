# 04 Option Schema Tightening

Status: `ready`

Suggested branch: `refactor/linuxbrew-option-schemas`

## Goal

Tighten option types and assertions so common misconfigurations fail earlier and
more clearly.

## Scope

- encode `compatSymlinks` as real pairs
- validate `brewPrefix` more strictly
- warn or fail clearly when `githubApiTokenFile` is unusable
