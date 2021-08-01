{ lib, pkgs, config, ... }:
with lib;
let
  backup = { name, paths, startAt ? "daily" }: {
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
    };
  };
in
{
  services.borgbackup = {
    jobs = backup {
      name = "etc_nixos";
      paths = [ "/etc/nixos/" ];
      startAt = [ "*-*-* 02:30" ];
    }
    // backup {
      name = "var";
      paths = [ "/var/" ];
      startAt = [ "*-*-* 01:00" ];
    }
    // backup {
      name = "data";
      paths = [ "/data/" ];
      startAt = [ "*-*-* 02:00" ];
    }
    // backup {
      name = "home";
      paths = [ "/home/" "/root/" ];
      startAt = [ "*-*-* 01:30" ];
    };
  };
}
