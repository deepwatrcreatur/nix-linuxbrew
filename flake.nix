{
  description = "A home-manager module for managing Homebrew (Linuxbrew) on Linux NixOS/nix systems";

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
      }
    ) // {
      homeManagerModules = {
        default = import ./modules/linuxbrew.nix;
        linuxbrew = import ./modules/linuxbrew.nix;
      };

      # Convenience alias
      homeManagerModule = import ./modules/linuxbrew.nix;
    };
}
