{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.programs.linuxbrew;

  brewPrefix = cfg.brewPrefix;

  # Packages needed by the Homebrew installer on NixOS
  installerDeps = [
    pkgs.coreutils
    pkgs.util-linux
    pkgs.gnugrep
    pkgs.gawk
    pkgs.git
    pkgs.curl
    pkgs.glibc.bin
    pkgs.findutils
    pkgs.gnused
    pkgs.gnutar
    pkgs.gzip
    pkgs.which
    pkgs.ruby
  ];

  # Packages needed at brew-run time (subset of above)
  runtimeDeps = [
    pkgs.coreutils
    pkgs.gnugrep
    pkgs.gawk
    pkgs.gnused
    pkgs.findutils
    pkgs.gnutar
    pkgs.gzip
    pkgs.which
    pkgs.openssh
  ];

  installBrewScript = pkgs.writeShellScript "install-brew-packages" ''
    # Don't use set -e; we want to continue even if some packages fail
    set -u

    # Skip linuxbrew setup in container environments - it's not compatible
    if [ -f /.dockerenv ] || grep -q 'lxc' /proc/1/cgroup 2>/dev/null; then
      echo "Skipping linuxbrew setup in container environment"
      exit 0
    fi

    # Install Homebrew if not present
    if [ ! -f "${brewPrefix}/bin/brew" ]; then
      echo "Installing Homebrew to ${brewPrefix}..."

      # Set up comprehensive PATH for homebrew installer on NixOS
      export PATH="${lib.makeBinPath installerDeps}:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin:$PATH"

      # Run the installer with proper environment
      # NONINTERACTIVE=1 prevents the script from prompting the user
      NONINTERACTIVE=1 ${pkgs.bash}/bin/bash -c "$(${pkgs.curl}/bin/curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

      if [ ! -x "${brewPrefix}/bin/brew" ]; then
        echo "Error: Homebrew installer did not produce ${brewPrefix}/bin/brew" >&2
        exit 1
      fi
    fi

    # Set up environment
    # Homebrew expects common core utilities in PATH.
    export PATH="${lib.makeBinPath runtimeDeps}:${brewPrefix}/bin:${brewPrefix}/sbin:$PATH"
    export HOMEBREW_PREFIX="${brewPrefix}"
    export HOMEBREW_CELLAR="${brewPrefix}/Cellar"
    export HOMEBREW_REPOSITORY="${brewPrefix}/Homebrew"

    # Prefer Nix-provided curl/git on NixOS.
    export HOMEBREW_CURL_PATH="${pkgs.curl}/bin/curl"
    export HOMEBREW_GIT_PATH="${pkgs.writeShellScript "brew-git" ''
      export PATH="${pkgs.openssh}/bin:$PATH"
      exec ${pkgs.git}/bin/git "$@"
    ''}"

    # Add taps (continue on failure)
    ${concatStringsSep "\n" (
      map (tap: ''
        if ! "${brewPrefix}/bin/brew" tap | ${pkgs.gnugrep}/bin/grep -q "^${tap}$"; then
          echo "Adding tap: ${tap}"
          "${brewPrefix}/bin/brew" tap "${tap}" || echo "Warning: Failed to add tap ${tap}"
        fi
      '') cfg.taps
    )}

    # Install and link brews (continue on failure)
    ${concatStringsSep "\n" (
      map (formula: ''
        if ! "${brewPrefix}/bin/brew" list "${formula}" &>/dev/null; then
          echo "Installing formula: ${formula}"
          "${brewPrefix}/bin/brew" install "${formula}" || echo "Warning: Failed to install ${formula}"
        fi
        # Ensure package is linked (overwrite stale links)
        "${brewPrefix}/bin/brew" link --overwrite "${formula}" 2>/dev/null || true
      '') cfg.brews
    )}

    echo "Homebrew setup complete!"
    echo "Run 'brew upgrade' to update outdated packages"
  '';
in
{
  options.programs.linuxbrew = {
    enable = mkEnableOption "Linuxbrew (Homebrew on Linux) integration";

    brewPrefix = mkOption {
      type = types.str;
      default = "/home/linuxbrew/.linuxbrew";
      description = "Path where Homebrew is (or will be) installed.";
    };

    taps = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "homebrew/cask" "myorg/mytap" ];
      description = "List of Homebrew taps to add.";
    };

    brews = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "hello" "wget" "jq" ];
      description = "List of Homebrew formulae to install.";
    };
  };

  config = mkIf cfg.enable {
    # Add Homebrew environment variables
    home.sessionVariables = {
      HOMEBREW_PREFIX = brewPrefix;
      HOMEBREW_CELLAR = "${brewPrefix}/Cellar";
      HOMEBREW_REPOSITORY = "${brewPrefix}/Homebrew";
      HOMEBREW_CURL_PATH = "${pkgs.curl}/bin/curl";
      HOMEBREW_GIT_PATH = "${pkgs.writeShellScript "brew-git" ''
        export PATH="${pkgs.openssh}/bin:$PATH"
        exec ${pkgs.git}/bin/git "$@"
      ''}";
    };

    # Shell integration — only when the respective shell program is enabled
    programs.bash.initExtra = mkIf config.programs.bash.enable ''
      if [ -f "${brewPrefix}/bin/brew" ]; then
        export PATH="${brewPrefix}/bin:${brewPrefix}/sbin:$PATH"
      fi
    '';

    programs.zsh.initExtra = mkIf config.programs.zsh.enable ''
      if [ -f "${brewPrefix}/bin/brew" ]; then
        export PATH="${brewPrefix}/bin:${brewPrefix}/sbin:$PATH"
      fi
    '';

    programs.fish.shellInit = mkIf config.programs.fish.enable ''
      if test -f "${brewPrefix}/bin/brew"
        fish_add_path --prepend "${brewPrefix}/bin" "${brewPrefix}/sbin"
      end
    '';

    programs.nushell.extraConfig = mkIf config.programs.nushell.enable ''
      if ("${brewPrefix}/bin/brew" | path exists) {
        $env.PATH = ($env.PATH | prepend "${brewPrefix}/bin" | prepend "${brewPrefix}/sbin")
      }
    '';

    # Make the install/update script available as a CLI command
    home.packages = [
      (pkgs.writeShellScriptBin "install-brew-packages" ''
        exec ${installBrewScript}
      '')
    ];

    # Run during home-manager activation (as user, not root)
    home.activation.installHomebrew = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      echo "Running Homebrew setup..."
      ${installBrewScript}
    '';
  };
}
