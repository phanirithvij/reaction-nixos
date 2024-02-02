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

  services.restic.backups.data2 = let
    pokiHost = "musi@192.168.1.74";
    pokiKey = "/var/secrets/backups/data2/sshkey";
  in {
    paths = [ "/data/" "/var/" "/etc/nixos/" "/home/" "/root/" "/nix/var/nix/" ];
    passwordFile = "/var/secrets/backups/data2/pass";
    extraOptions = [
      "sftp.command='ssh ${pokiHost} -i ${pokiKey} -s sftp'"
    ];
    repository = "sftp:${pokiHost}:/backup/musi/restic";
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
    backupPrepareCommand = "${pkgs.writeScript "wake-poki" ''
      ${pkgs.wakelan}/bin/wakelan A0:B3:CC:E9:4C:9C
      for _ in $(seq 60)
      do
        sleep 5
        ssh ${pokiHost} -i ${pokiKey} -o ConnectTimeout=10 true && break
      done
    ''}";
  };
}
