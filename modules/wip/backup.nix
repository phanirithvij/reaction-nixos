{ lib, pkgs, config, ... }:
with lib;
let
  defaults = {
      encryption = {
        mode = ???;
        passCommand = "cat /prout";
      };
      compression = "auto";
      environment = {
        BORG_RSH = "ssh -i /path/to/key";
      };
      repo = "ssh://user@host:port/path/to/repo";
  };
in {
  # backup /data
  # backup /home
  # backup /var
  # backup /root
  services.borgbackup.jobs = {
    slashHome = defaults // {
      paths = [ "/home" ];
      startAt = "daily"; # How to specify at night?
      prune.keep = {
        within = "1d"; # Keep all archives from the last day
        daily = 7;
        weekly = 4;
        monthly = -1;  # Keep at least one archive for each month
      };
    };
  };
}
