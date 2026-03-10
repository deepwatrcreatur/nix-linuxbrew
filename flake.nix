{
  description = "A home-manager module for managing Homebrew (Linuxbrew) on Linux NixOS/nix systems";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }: {
    homeManagerModules = {
      default = import ./modules/linuxbrew.nix;
      linuxbrew = import ./modules/linuxbrew.nix;
    };

    # Convenience alias
    homeManagerModule = import ./modules/linuxbrew.nix;
  };
}
