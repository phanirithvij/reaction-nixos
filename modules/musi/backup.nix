{ lib, pkgs, config, ... }:
with lib;
let
  backup = { name, paths, startAt ? "daily", extraArgs ? {} }: {
    "${name}" = {
        paths = paths;
        startAt = startAt;
        prune.keep = {
          within = "1d"; # Keep all archives from the last day
          daily = 7;
          weekly = 4;
          monthly = -1;  # Keep at least one archive for each month
        };
        encryption = {
          mode = "repokey-blake2";
          passCommand = "cat /var/secrets/backups/${name}/pass";
        };
        compression = "lz4";
        environment = {
          BORG_RSH = "ssh -i /var/secrets/backups/${name}/sshkey";
        };
        repo = "ppom@node.cmercier.fr:/pacobackup/${name}";
    } // extraArgs;
  };
in
{
  services.postgresqlBackup = {
    enable = true;
    # every 2 hours, it only costs 2s of CPU time for now
    startAt = "*-*-* 0/2:15";
  };

  services.borgbackup = {
    jobs = backup {
      name = "data";
      paths = [ "/data/" "/var/" "/etc/nixos/" "/home/" "/root/" ];
      startAt = [ "*-*-* 02:00" ];
    };
  };
}
