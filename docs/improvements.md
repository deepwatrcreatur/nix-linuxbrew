# Improvements for nix-linuxbrew

## Current strengths

- Clear split between root-owned NixOS setup (`nixosModules.default`) and user-owned Home Manager setup (`homeManagerModules.default`).
- Good safety posture in the NixOS module (dangerous parent-path guard and explicit assertions).
- Practical compatibility story (`brew-wrapper`, runtime deps, token support, and optional compiler bootstrap).

## Recommended improvements

### 1) Add reproducibility controls for the Homebrew installer (high impact)

The installer is currently fetched live from `raw.githubusercontent.com` during activation, which introduces non-determinism and supply-chain risk.

**Suggestions**

- Add an option such as `programs.linuxbrew.installerSource` with modes:
  - `"upstream-head"` (current behavior)
  - `"pinned-url"` (explicit URL)
  - `"local-file"` (vendored script path)
- Add optional `installerSha256` verification when using remote sources.
- Document a “fully pinned” setup pattern in README.

### 2) Introduce a dry-run / plan mode for package operations (high impact)

Activation currently makes direct changes (tap/install/link). A plan mode would improve confidence before running stateful operations.

**Suggestions**

- Add `programs.linuxbrew.dryRun` (bool).
- In dry-run mode, print exact `brew` commands that would run for taps/brews/compiler steps.
- Optionally expose `install-brew-packages --plan` and keep this script callable outside activation.

### 3) Improve failure reporting and observability (high impact)

The installer intentionally continues on some failures (good UX), but failures are only echoed inline.

**Suggestions**

- Track failures and emit a final summary with counts and package names.
- Add an option for strict mode (e.g., `failOnPackageError`) that exits non-zero if any package install/link fails.
- Emit a stable log prefix (`[nix-linuxbrew]`) for easier journald filtering.

### 4) Tighten option schemas and assertions (medium impact)

Some options could be validated more strictly to catch misconfigurations early.

**Suggestions**

- Change `compatSymlinks` type from `listOf (listOf str)` to `listOf (tuple [ str str ])` to encode pair-ness in type.
- Add assertion to ensure `brewPrefix` is absolute and does not contain trailing slash edge cases.
- Validate `githubApiTokenFile` readability only when set (warning if unreadable at activation time).

### 5) Expand CI checks beyond eval-only coverage (medium impact)

Current checks validate module evaluation/build outputs. Runtime script quality can be strengthened with static checks.

**Suggestions**

- Add `shellcheck` checks for generated shell snippets where practical.
- Add a small matrix of Nix eval tests for option combinations:
  - `ensureCompiler = false`
  - non-default `brewPrefix`
  - `allowContainerInstall = true`
  - custom `compatSymlinks = []`

### 6) Reduce duplication between wrapper implementations (medium impact)

`brew-wrapper` logic exists in both `flake.nix` and `modules/linuxbrew.nix` with similar compiler/env handling.

**Suggestions**

- Extract shared wrapper script construction into one helper derivation.
- Reuse that helper from both flake package and module option `installWrapper` path.

### 7) Improve multi-user guidance and defaults (medium impact)

The default owner resolution in NixOS uses first regular user, which may be surprising on multi-user systems.

**Suggestions**

- Add a warning when `owner = null` and more than one regular user exists.
- In docs, recommend explicitly setting `programs.linuxbrew.owner` for shared machines.
- Add a short “single-user vs multi-user” config section in README.

### 8) Add lightweight maintenance ergonomics (nice-to-have)

A few additional options would reduce manual upkeep.

**Suggestions**

- Optional `programs.linuxbrew.autoUpgrade` (runs `brew update && brew upgrade` during activation or via user service).
- Optional `cleanup` behavior (`brew autoremove`, `brew cleanup`) gated by explicit opt-in.
- Optional command timeout / retries for network-dependent steps.

## Suggested implementation order

1. Reproducibility controls for installer source + hash verification.
2. Dry-run mode and improved failure summaries.
3. Option/schema tightening and wrapper deduplication.
4. CI/static checks and docs expansion for multi-user/operations guidance.
