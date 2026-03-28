# Improvements for nix-linuxbrew

## Scope

This document tracks potential improvements to the nix-linuxbrew flake and its modules. Items are intentionally high level and can be split into smaller issues or pull requests.

## Documentation

- Add a short "Security & system impact" section describing the compatibility symlinks created by the NixOS module and their implications.
- Document `githubApiTokenFile`, `installWrapper`, and `ensureCompiler` with concrete home-manager configuration examples.
- Document container detection behavior (Docker/LXC skip) and how to opt out, with clear caveats.

## Module / API

- Expose an option to configure or disable compatibility symlink creation in the NixOS module instead of hard-coding `compatLinks`.
- Consider an option such as `programs.linuxbrew.extraBrewEnv` for injecting additional environment variables into the wrapper and installer script.
- Allow override or extension of `installerDeps` and `runtimeDeps` via options for edge cases that require extra tools.

## Flake outputs

- Add a `checks` flake output that instantiates a minimal NixOS + home-manager configuration using the modules, to be run by `nix flake check`.
- Add a `devShell` output with basic development tools (nix, home-manager, git, formatter) for contributors.
- Expose a `formatter` output (e.g., nixfmt-rfc-style) so `nix fmt` can be used consistently.

## Testing / CI

- Add CI (GitHub Actions and/or Codeberg CI) that runs `nix flake check` on at least one Linux system and validates the example configurations in the README.

## Longer-term ideas

- Offer a dry-run mode that only prints which taps and brews would be changed without invoking Homebrew.
- Investigate caching or pinning of the Homebrew installer script to reduce dependence on live network access during activation.
