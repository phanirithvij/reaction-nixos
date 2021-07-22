{ lib, pkgs, config, ... }:
with lib;
{
  services.borgbackup = {
    jobs = {
      # Test backup of /etc/nixos
      etc_nixos = {
        paths = [ "/etc/nixos/" ];
        # startAt = "daily"; # How to specify at night?
        startAt = [ "*-*-* 02:30" ];
        prune.keep = {
          within = "1d"; # Keep all archives from the last day
          daily = 7;
          weekly = 4;
          monthly = -1;  # Keep at least one archive for each month
        };
        encryption = {
          mode = "repokey-blake2";
          passCommand = "cat /var/secrets/backups/etc_nixos/pass";
        };
        compression = "lz4";
        environment = {
          BORG_RSH = "ssh -p ${toString (builtins.head config.services.openssh.ports)} -i /var/secrets/backups/etc_nixos/key";
        };
        repo = "borg@localhost:.";
      };

      # Real backup of /var/
      var = {
        paths = [ "/var/" ];
        # startAt = "daily"; # How to specify at night?
        startAt = [ "*-*-* 01:00" ];
        prune.keep = {
          within = "1d"; # Keep all archives from the last day
          daily = 7;
          weekly = 4;
          monthly = -1;  # Keep at least one archive for each month
        };
        encryption = {
          mode = "repokey-blake2";
          passCommand = "cat /var/secrets/backups/var/pass";
        };
        compression = "lz4";
        environment = {
          BORG_RSH = "ssh -i /var/secrets/backups/var/sshkey";
        };
        repo = "ppom@node.cmercier.fr:/pacobackup/var";
      };

      # Real backup of /data/
      data = {
        paths = [ "/data/" ];
        # startAt = "daily"; # How to specify at night?
        startAt = [ "*-*-* 02:00" ];
        prune.keep = {
          within = "1d"; # Keep all archives from the last day
          daily = 7;
          weekly = 4;
          monthly = -1;  # Keep at least one archive for each month
        };
        encryption = {
          mode = "repokey-blake2";
          passCommand = "cat /var/secrets/backups/data/pass";
        };
        compression = "lz4";
        environment = {
          BORG_RSH = "ssh -i /var/secrets/backups/data/sshkey";
        };
        repo = "ppom@node.cmercier.fr:/pacobackup/data";
      };

      # Real backup of /home/ & /root/
      home = {
        paths = [ "/home/" "/root/" ];
        # startAt = "daily"; # How to specify at night?
        startAt = [ "*-*-* 01:30" ];
        prune.keep = {
          within = "1d"; # Keep all archives from the last day
          daily = 7;
          weekly = 4;
          monthly = -1;  # Keep at least one archive for each month
        };
        encryption = {
          mode = "repokey-blake2";
          passCommand = "cat /var/secrets/backups/home/pass";
        };
        compression = "lz4";
        environment = {
          BORG_RSH = "ssh -i /var/secrets/backups/home/sshkey";
        };
        repo = "ppom@node.cmercier.fr:/pacobackup/home";
      };
    };

    repos = {
      etc_nixos = {
        authorizedKeys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINOs365Kt31fWF2ovLwmpSWdfsZ8v61OhEaRkD4Altyk root@musi"
        ] ;
        path = "/var/lib/backups/etc_nixos" ;
      };
    };
  };

}
