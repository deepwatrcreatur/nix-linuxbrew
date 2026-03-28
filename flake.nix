{
  description = "NixOS and home-manager modules for managing Homebrew (Linuxbrew) on Linux NixOS/nix systems";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, home-manager, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        brewPrefix = "/home/linuxbrew/.linuxbrew";
        formatterPkg = pkgs.nixfmt-rfc-style or pkgs.nixpkgs-fmt;
      in
      {
        packages = {
          # Wrapper that always sets environment variables
          brew-wrapper = pkgs.writeShellScriptBin "brew" ''
            export HOMEBREW_PREFIX="${brewPrefix}"
            export HOMEBREW_CELLAR="${brewPrefix}/Cellar"
            export HOMEBREW_REPOSITORY="${brewPrefix}/Homebrew"
            export HOMEBREW_CURL_PATH="${pkgs.curl}/bin/curl"
            export HOMEBREW_GIT_PATH="${pkgs.writeShellScript "brew-git" ''
              export PATH="${pkgs.openssh}/bin:$PATH"
              exec ${pkgs.git}/bin/git "$@"
            ''}"

            # Set compiler preferences (prefer clang if available, fallback to gcc)
            if [ -x "${brewPrefix}/bin/clang" ]; then
              export HOMEBREW_CC="${brewPrefix}/bin/clang"
              export HOMEBREW_CXX="${brewPrefix}/bin/clang++"
            elif [ -x "${brewPrefix}/bin/gcc" ]; then
              export HOMEBREW_CC="${brewPrefix}/bin/gcc"
              export HOMEBREW_CXX="${brewPrefix}/bin/g++"
            elif [ -x "${brewPrefix}/bin/gcc-15" ]; then
              export HOMEBREW_CC="${brewPrefix}/bin/gcc-15"
              export HOMEBREW_CXX="${brewPrefix}/bin/g++-15"
            fi

            # Add Homebrew to PATH for this invocation
            export PATH="${brewPrefix}/bin:${brewPrefix}/sbin:${pkgs.openssh}/bin:$PATH"

            exec ${brewPrefix}/bin/brew "$@"
          '';

          default = self.packages.${system}.brew-wrapper;
        };

        formatter = formatterPkg;

        devShells.default = pkgs.mkShell {
          packages = [
            formatterPkg
            pkgs.git
          ];
        };

        checks = if pkgs.stdenv.isLinux then {
          nixos-basic = (nixpkgs.lib.nixosSystem {
            inherit system;
            modules = [
              self.nixosModules.default
              {
                programs.linuxbrew.enableSystemSetup = true;
                fileSystems."/" = {
                  device = "none";
                  fsType = "tmpfs";
                };
                boot.loader.grub.devices = [ "nodev" ];
                system.stateVersion = "24.11";
              }
            ];
          }).config.system.build.toplevel;

          home-manager-basic = (home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            modules = [
              self.homeManagerModules.default
              {
                home.username = "test-user";
                home.homeDirectory = "/home/test-user";
                home.stateVersion = "24.11";
                programs.linuxbrew = {
                  enable = true;
                  brews = [ "hello" ];
                };
              }
            ];
          }).activationPackage;
        } else {};
      }
    )
    // {
      # NixOS system modules (for root-level setup)
      nixosModules = {
        default = import ./modules/nixos-linuxbrew.nix;
        linuxbrew = import ./modules/nixos-linuxbrew.nix;
      };

      # Convenience alias
      nixosModule = import ./modules/nixos-linuxbrew.nix;

      # Home Manager modules (for user-level setup)
      homeManagerModules = {
        default = import ./modules/linuxbrew.nix;
        linuxbrew = import ./modules/linuxbrew.nix;
      };

      # Convenience alias
      homeManagerModule = import ./modules/linuxbrew.nix;
    };
}
