{ lib, pkgs, config, ... }:
with lib;
{
  # CLIENT
  # backup /data
  # backup /home && /root
  # backup /var
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
