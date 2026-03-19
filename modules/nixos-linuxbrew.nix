{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.programs.linuxbrew;
in
{
  options.programs.linuxbrew = {
    enableSystemSetup = mkEnableOption "system-level linuxbrew directory setup (requires root)";

    brewPrefix = mkOption {
      type = types.str;
      default = "/home/linuxbrew/.linuxbrew";
      description = "Path where Homebrew is (or will be) installed.";
    };
  };

  config = mkIf cfg.enableSystemSetup {
    system.activationScripts.linuxbrew.text = ''
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
    '';
  };
}
