{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.programs.linuxbrew;

  # Get the parent directory of brewPrefix (e.g., /home/linuxbrew from /home/linuxbrew/.linuxbrew)
  brewParentDir = dirOf cfg.brewPrefix;

  # Compatibility symlinks for Homebrew installer on NixOS
  # Homebrew expects certain tools in /bin and /usr/bin
  compatLinks = [
    [ "${pkgs.coreutils}/bin/nice" "/usr/bin/nice" ]
    [ "${pkgs.coreutils}/bin/mkdir" "/bin/mkdir" ]
    [ "${pkgs.coreutils}/bin/chmod" "/bin/chmod" ]
    [ "${pkgs.coreutils}/bin/chown" "/bin/chown" ]
    [ "${pkgs.coreutils}/bin/chgrp" "/bin/chgrp" ]
    [ "${pkgs.coreutils}/bin/touch" "/bin/touch" ]
    [ "${pkgs.coreutils}/bin/readlink" "/bin/readlink" ]
    [ "${pkgs.coreutils}/bin/cat" "/bin/cat" ]
    [ "${pkgs.coreutils}/bin/sort" "/bin/sort" ]
    [ "${pkgs.coreutils}/bin/mv" "/bin/mv" ]
    [ "${pkgs.coreutils}/bin/rm" "/bin/rm" ]
    [ "${pkgs.coreutils}/bin/ln" "/bin/ln" ]
    [ "${pkgs.coreutils}/bin/dirname" "/bin/dirname" ]
    [ "${pkgs.coreutils}/bin/basename" "/bin/basename" ]
    [ "${pkgs.coreutils}/bin/uname" "/bin/uname" ]
    [ "${pkgs.coreutils}/bin/sha256sum" "/bin/sha256sum" ]
    [ "${pkgs.gnutar}/bin/tar" "/bin/tar" ]
    [ "${pkgs.gzip}/bin/gzip" "/bin/gzip" ]
    [ "${pkgs.gnugrep}/bin/grep" "/bin/grep" ]
    [ "${pkgs.bash}/bin/bash" "/bin/bash" ]
    [ "${pkgs.util-linux}/bin/flock" "/usr/bin/flock" ]
    [ "${pkgs.coreutils}/bin/stat" "/usr/bin/stat" ]
    [ "${pkgs.coreutils}/bin/cut" "/usr/bin/cut" ]
    [ "${pkgs.coreutils}/bin/dirname" "/usr/bin/dirname" ]
    [ "${pkgs.coreutils}/bin/sha256sum" "/usr/bin/sha256sum" ]
    [ "${pkgs.glibc.bin}/bin/ldd" "/usr/bin/ldd" ]
  ];

  # Pinned paths for core utilities
  mkdir = "${pkgs.coreutils}/bin/mkdir";
  chown = "${pkgs.coreutils}/bin/chown";
  chmod = "${pkgs.coreutils}/bin/chmod";
  ln = "${pkgs.coreutils}/bin/ln";
  id = "${pkgs.coreutils}/bin/id";
  awk = "${pkgs.gawk}/bin/awk";

  # Safety check: list of directories that should never be chowned
  dangerousPaths = [ "/" "/bin" "/boot" "/dev" "/etc" "/home" "/lib" "/lib64" "/mnt" "/nix" "/opt" "/proc" "/root" "/run" "/sbin" "/srv" "/sys" "/tmp" "/usr" "/var" ];

  linuxbrewSetupScript = pkgs.writeShellScript "linuxbrew-system-setup" ''
    set -euo pipefail

    BREW_PREFIX="${cfg.brewPrefix}"
    BREW_PARENT="${brewParentDir}"

    # Safety check: prevent catastrophic chown on system directories
    for dangerous in ${concatStringsSep " " dangerousPaths}; do
      if [ "$BREW_PARENT" = "$dangerous" ]; then
        echo "Error: brewPrefix parent '$BREW_PARENT' is a protected system directory." >&2
        echo "Please use a prefix like '/home/linuxbrew/.linuxbrew' or '/opt/linuxbrew/.linuxbrew'" >&2
        exit 1
      fi
    done

    # Ensure parent directory exists first
    if [ ! -d "$BREW_PARENT" ]; then
      ${mkdir} -p "$BREW_PARENT"
    fi

    # Then create the prefix directory
    if [ ! -d "$BREW_PREFIX" ]; then
      ${mkdir} -p "$BREW_PREFIX"
    fi

    # Determine owner - use configured owner or fall back to first regular user
    ${if cfg.owner != null then ''
      # Use explicitly configured owner - resolve at runtime
      if ! ${id} "${cfg.owner}" &>/dev/null; then
        echo "Error: Configured owner '${cfg.owner}' does not exist" >&2
        exit 1
      fi
      OWNER_UID=$(${id} -u "${cfg.owner}")
      OWNER_GID=$(${id} -g "${cfg.owner}")
    '' else ''
      # Fall back to first regular user (UID >= 1000, not nobody)
      REGULAR_USER=$(${awk} -F: '$3 >= 1000 && $3 != 65534 { print $1; exit }' /etc/passwd)
      if [ -n "$REGULAR_USER" ]; then
        OWNER_UID=$(${id} -u "$REGULAR_USER")
        OWNER_GID=$(${id} -g "$REGULAR_USER")
      else
        echo "Warning: No regular user found and no owner configured. Directory will be root-owned." >&2
        echo "Consider setting programs.linuxbrew.owner to specify the intended user." >&2
        OWNER_UID=""
        OWNER_GID=""
      fi
    ''}

    # Set ownership: non-recursive on parent, recursive only on prefix
    if [ -n "''${OWNER_UID:-}" ] && [ -n "''${OWNER_GID:-}" ]; then
      # Non-recursive chown on parent directory (safe)
      ${chown} "$OWNER_UID:$OWNER_GID" "$BREW_PARENT"
      ${chmod} 755 "$BREW_PARENT"
      # Recursive chown only on the actual prefix directory
      ${chown} -R "$OWNER_UID:$OWNER_GID" "$BREW_PREFIX"
    fi

    # Create compatibility symlinks for Homebrew installer
    ${mkdir} -p /bin /usr/bin
    ${concatMapStringsSep "\n" (link: ''${ln} -sf ${builtins.elemAt link 0} ${builtins.elemAt link 1}'') compatLinks}
  '';
in
{
  options.programs.linuxbrew = {
    enableSystemSetup = mkEnableOption "system-level linuxbrew directory setup and compatibility symlinks (requires root)";

    brewPrefix = mkOption {
      type = types.str;
      default = "/home/linuxbrew/.linuxbrew";
      description = ''
        Path where Homebrew is (or will be) installed.
        The parent directory of this path will be created and owned by the specified user.
        For safety, the parent directory must not be a system directory like /opt, /usr, etc.
      '';
    };

    owner = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "myuser";
      description = ''
        Username who should own the Homebrew directory.
        If not set, defaults to the first regular user (UID >= 1000) found in /etc/passwd.
        On multi-user systems, you should explicitly set this to the user who will run home-manager.
      '';
    };
  };

  config = mkIf cfg.enableSystemSetup {
    # Assertion to catch dangerous configurations at evaluation time
    assertions = [
      {
        assertion = !(builtins.elem brewParentDir dangerousPaths);
        message = ''
          programs.linuxbrew.brewPrefix is set to "${cfg.brewPrefix}" which has parent
          directory "${brewParentDir}". This is a protected system directory and would
          cause dangerous ownership changes. Please use a safer prefix like
          "/home/linuxbrew/.linuxbrew" or "/opt/linuxbrew/.linuxbrew".
        '';
      }
    ];

    system.activationScripts.linuxbrew.text = ''
      echo "Running Linuxbrew system setup script and compatibility link setup..."
      ${linuxbrewSetupScript}
    '';
  };
}
