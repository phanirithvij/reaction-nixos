{ lib, pkgs, config, ... }:
with lib;
let
in {
  services.postgresqlBackup = {
    enable = true;
    # every 6 hours, it only costs 2s of CPU time for now
    startAt = "*-*-* 0/6:15";
  };

  services.mysqlBackup = {
    enable = true;
    # every 6 hours, it only costs 2s of CPU time for now
    calendar = "*-*-* 0/6:15";
  };

  services.restic.backups.data = {
    paths = [ "/data/" "/var/" "/etc/nixos/" "/home/" "/root/" "/nix/var/nix/" ];
    passwordFile = "/var/secrets/backups/data/pass";
    extraOptions = [
      "sftp.command='ssh ppom@node.cmercier.fr -i /var/secrets/backups/data/sshkey -s sftp'"
    ];
    repository = "sftp:ppom@node.cmercier.fr:/pacobackup/data";
    initialize = true;
    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 5"
      "--keep-monthly 12"
    ];
    exclude = [
      "/var/cache"
      "/home/*/.cache"
    ];
    timerConfig = {
      OnCalendar = [ "02:00" ];
      RandomizedDelaySec = "30m";
    };
  };

  services.restic.backups.data2 = {
    paths = [ "/data/" "/var/" "/etc/nixos/" "/home/" "/root/" "/nix/var/nix/" ];
    passwordFile = "/var/secrets/backups/data2/pass";
    extraOptions = [
      "sftp.command='ssh musi@192.168.1.74 -i /var/secrets/backups/data2/sshkey -s sftp'"
    ];
    repository = "sftp:musi@192.168.1.74:/backup/musi/restic";
    initialize = true;
    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 5"
      "--keep-monthly 12"
    ];
    exclude = [
      "/var/cache"
      "/home/*/.cache"
    ];
    timerConfig = {
      OnCalendar = [ "04:00" ];
      RandomizedDelaySec = "30m";
    };
  };
}
