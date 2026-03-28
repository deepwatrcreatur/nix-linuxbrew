# nix-linuxbrew

NixOS and [home-manager](https://github.com/nix-community/home-manager) modules for managing [Homebrew (Linuxbrew)](https://docs.brew.sh/Homebrew-on-Linux) on Linux NixOS/nix systems.

## Features

- **NixOS module**: Creates `/home/linuxbrew` directory with proper ownership (requires root)
- **Home-manager module**: Installs Homebrew and manages packages as your user
- Declaratively manages taps and formulae
- Integrates Homebrew into your shell (bash, zsh, fish, nushell)
- Sets the standard Homebrew environment variables and prefers Nix-provided `curl`/`git`
- Exposes an `install-brew-packages` command you can re-run at any time
- Provides a `brew-wrapper` package that works without shell restarts

## Installation

### 1. Add the flake input

```nix
# flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-linuxbrew = {
      url = "github:deepwatrcreatur/nix-linuxbrew";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
```

### 2. Configure NixOS (system-level setup)

The NixOS module creates the `/home/linuxbrew` directory with proper ownership. This runs as root during system activation.

```nix
# configuration.nix or your NixOS host module
{ inputs, ... }:
{
  imports = [ inputs.nix-linuxbrew.nixosModules.default ];

  programs.linuxbrew.enableSystemSetup = true;
}
```

### 3. Configure home-manager (user-level setup)

The home-manager module installs Homebrew and manages packages as your user.

```nix
# home.nix
{ inputs, ... }:
{
  imports = [ inputs.nix-linuxbrew.homeManagerModules.default ];

  programs.linuxbrew = {
    enable = true;

    taps = [
      "homebrew/bundle"
    ];

    brews = [
      "hello"
      "jq"
      "wget"
    ];
  };
}
```

## Usage Options

### Quick Start (Wrapper Package Only)

If you just want the `brew` command without declarative package management:

```nix
{
  inputs.nix-linuxbrew.url = "github:deepwatrcreatur/nix-linuxbrew";

  # Add just the wrapper - no module import needed
  home.packages = [ inputs.nix-linuxbrew.packages.${system}.brew-wrapper ];
}
```

The wrapper automatically sets `HOMEBREW_CURL_PATH` and `HOMEBREW_GIT_PATH` on every `brew` invocation.

### Full Integration (Recommended)

For complete integration with both system-level directory setup and user-level package management:

```nix
# flake.nix
{
  outputs = { nixpkgs, home-manager, nix-linuxbrew, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        nix-linuxbrew.nixosModules.default
        {
          programs.linuxbrew.enableSystemSetup = true;
        }
        home-manager.nixosModules.home-manager
        {
          home-manager.users.myuser = {
            imports = [ nix-linuxbrew.homeManagerModules.default ];
            programs.linuxbrew = {
              enable = true;
              brews = [ "hello" "jq" ];
            };
          };
        }
      ];
    };
  };
}
```

## Module Reference

### NixOS Module Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `programs.linuxbrew.enableSystemSetup` | `bool` | `false` | Create `/home/linuxbrew` directory with proper ownership |
| `programs.linuxbrew.brewPrefix` | `str` | `/home/linuxbrew/.linuxbrew` | Homebrew installation prefix |

### Home-Manager Module Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `programs.linuxbrew.enable` | `bool` | `false` | Enable the module |
| `programs.linuxbrew.brewPrefix` | `str` | `/home/linuxbrew/.linuxbrew` | Homebrew installation prefix |
| `programs.linuxbrew.taps` | `[str]` | `[]` | Homebrew taps to add |
| `programs.linuxbrew.brews` | `[str]` | `[]` | Homebrew formulae to install |
| `programs.linuxbrew.ensureCompiler` | `bool` | `true` | Auto-install LLVM for building from source |
| `programs.linuxbrew.githubApiTokenFile` | `null or str` | `null` | Optional path to a GitHub token file for Homebrew API access |
| `programs.linuxbrew.installWrapper` | `bool` | `false` | Add a `brew` wrapper package to `home.packages` |

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     NixOS Activation                         │
│  (runs as root)                                              │
│                                                              │
│  nixosModules.default                                        │
│  └── Creates /home/linuxbrew with proper ownership           │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                  Home-Manager Activation                     │
│  (runs as user)                                              │
│                                                              │
│  homeManagerModules.default                                  │
│  ├── Installs Homebrew (if not present)                     │
│  ├── Installs LLVM compiler (if ensureCompiler = true)      │
│  ├── Adds configured taps                                    │
│  ├── Installs configured formulae                            │
│  └── Configures shell integration                            │
└─────────────────────────────────────────────────────────────┘
```

## Notes

- Homebrew is installed under `/home/linuxbrew/.linuxbrew` by default (the standard Linuxbrew location).
- The NixOS module should be used on NixOS systems to ensure the directory exists with proper permissions before home-manager runs.
- The home-manager module skips setup inside Docker/LXC container environments by default, where Homebrew is unsupported. Set `programs.linuxbrew.allowContainerInstall = true;` to override this behaviour (not generally recommended).
- After the initial `home-manager switch`, run `brew upgrade` to keep your packages up to date.
- The `install-brew-packages` command is added to your PATH so you can re-run the install/link logic at any time.

## Why Two Modules?

On NixOS, creating `/home/linuxbrew` requires root privileges because:

1. The directory is outside the user's home directory
2. It needs specific ownership set for the regular user

The NixOS module runs during system activation (as root) to create this directory. The home-manager module then runs as your user to install Homebrew and packages.

If you're not on NixOS (e.g., using nix + home-manager on another Linux distro), you may need to manually create the directory:

```bash
sudo mkdir -p /home/linuxbrew/.linuxbrew
sudo chown -R $(id -u):$(id -g) /home/linuxbrew
```

## Security & system impact

The NixOS module can create a set of compatibility symlinks in `/bin` and `/usr/bin` so that the Homebrew installer finds the core tools it expects. These symlinks point to immutable Nix store binaries such as `coreutils`, `bash`, and `tar`.

You can customise or disable this behaviour via `programs.linuxbrew.compatSymlinks`. Set it to `[]` to skip creating any symlinks, or override it with your own list of `[ source target ]` pairs.

## Advanced configuration examples

### Using a GitHub token with Homebrew

```nix
programs.linuxbrew = {
  enable = true;
  githubApiTokenFile = "${config.home.homeDirectory}/.local/share/agenix-user-secrets/github-token";
};
```

### Making the `brew` wrapper available immediately

```nix
programs.linuxbrew = {
  enable = true;
  installWrapper = true;
  brews = [ "hello" "jq" ];
};
```

### Managing the compiler toolchain explicitly

```nix
programs.linuxbrew = {
  enable = true;
  ensureCompiler = false; # skip automatic LLVM install
};
```

### Allowing Homebrew in containers (not generally recommended)

```nix
programs.linuxbrew = {
  enable = true;
  allowContainerInstall = true;
};
```

### Running linuxbrew in dry-run mode

```nix
{ pkgs, ... }:

{
  programs.linuxbrew = {
    enable = true;
    dryRun = true; # only print what would change, do not call brew

    taps = [ "homebrew/core" ];
    brews = [ "hello" "wget" ];
  };
}
```

### Using a pinned Homebrew installer script

```nix
{ pkgs, ... }:

{
  programs.linuxbrew = {
    enable = true;

    # Pin the Homebrew installer script via Nix instead of fetching at runtime
    installerScript = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh";
      sha256 = "<fill-in-real-hash>";
    };
  };
}
```

### Adding extra tools and environment for Homebrew

```nix
{ pkgs, ... }:

{
  programs.linuxbrew = {
    enable = true;

    extraInstallerDeps = [ pkgs.git pkgs.wget ];
    extraRuntimeDeps = [ pkgs.wget ];

    extraBrewEnv = {
      HOMEBREW_NO_ANALYTICS = "1";
      HTTP_PROXY = "http://proxy:8080";
    };
  };
}
```
