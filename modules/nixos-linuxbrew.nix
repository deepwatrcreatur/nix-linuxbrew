{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.programs.linuxbrew;

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

  linuxbrewSetupScript = pkgs.writeShellScript "linuxbrew-system-setup" ''
    # Create linuxbrew directory with proper permissions
    if [ ! -d /home/linuxbrew ]; then
      mkdir -p ${cfg.brewPrefix}
      # Find the first regular user (UID >= 1000, not nobody)
      REGULAR_USER=$(${pkgs.gawk}/bin/awk -F: '$3 >= 1000 && $3 != 65534 { print $1; exit }' /etc/passwd)
      if [ -n "$REGULAR_USER" ]; then
        USER_UID=$(id -u "$REGULAR_USER")
        USER_GID=$(id -g "$REGULAR_USER")
        chown -R $USER_UID:$USER_GID /home/linuxbrew
        chmod 755 /home/linuxbrew
      fi
    fi

    # Create compatibility symlinks for Homebrew installer
    mkdir -p /bin /usr/bin
    ${concatMapStringsSep "\n" (link: ''ln -sf ${builtins.elemAt link 0} ${builtins.elemAt link 1}'') compatLinks}
  '';
in
{
  options.programs.linuxbrew = {
    enableSystemSetup = mkEnableOption "system-level linuxbrew directory setup and compatibility symlinks (requires root)";

    brewPrefix = mkOption {
      type = types.str;
      default = "/home/linuxbrew/.linuxbrew";
      description = "Path where Homebrew is (or will be) installed.";
    };
  };

  config = mkIf cfg.enableSystemSetup {
    system.activationScripts.linuxbrew.text = ''
      echo "Running Linuxbrew system setup script and compatibility link setup..."
      ${linuxbrewSetupScript}
    '';
  };
}
