# nix-linuxbrew

A [home-manager](https://github.com/nix-community/home-manager) module that lets Nix users on Linux install and manage packages through [Homebrew (Linuxbrew)](https://docs.brew.sh/Homebrew-on-Linux).

## Features

- Automatically installs Homebrew the first time home-manager activates
- Declaratively manages taps and formulae
- Integrates Homebrew into your shell (bash, zsh, fish, nushell)
- Sets the standard Homebrew environment variables and prefers Nix-provided `curl`/`git`
- Exposes an `install-brew-packages` command you can re-run at any time

## Usage

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

  outputs = { nixpkgs, home-manager, nix-linuxbrew, ... }: {
    homeConfigurations."youruser" = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      modules = [
        nix-linuxbrew.homeManagerModules.default
        ./home.nix
      ];
    };
  };
}
```

### 2. Enable the module and declare packages

```nix
# home.nix
{
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

### Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `programs.linuxbrew.enable` | `bool` | `false` | Enable the module |
| `programs.linuxbrew.brewPrefix` | `str` | `/home/linuxbrew/.linuxbrew` | Homebrew installation prefix |
| `programs.linuxbrew.taps` | `[str]` | `[]` | Homebrew taps to add |
| `programs.linuxbrew.brews` | `[str]` | `[]` | Homebrew formulae to install |

## Notes

- Homebrew is installed under `/home/linuxbrew/.linuxbrew` by default (the standard Linuxbrew location).
- The module skips setup inside Docker / LXC container environments, where Homebrew is unsupported.
- After the initial `home-manager switch`, run `brew upgrade` to keep your packages up to date.
- The `install-brew-packages` command is added to your PATH so you can re-run the install/link logic at any time.