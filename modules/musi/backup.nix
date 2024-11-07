{ lib, pkgs, config, ... }:
let
  hosts = builtins.fromTOML (builtins.readFile ../common/hosts.toml);
in {
  services.postgresqlBackup = {
    enable = true;
    # every 6 hours, it only costs 2s of CPU time for now
    startAt = "*-*-* 0/6:15";
  };

  # services.restic.backups.data = {
  #   paths = [ "/data/" "/var/" "/etc/nixos/" "/home/" "/root/" "/nix/var/nix/" ];
  #   passwordFile = "/var/secrets/backups/data/pass";
  #   extraOptions = [
  #     "sftp.command='ssh ppom@node.cmercier.fr -i /var/secrets/backups/data/sshkey -s sftp'"
  #   ];
  #   repository = "sftp:ppom@node.cmercier.fr:/pacobackup/data";
  #   initialize = true;
  #   pruneOpts = [
  #     "--keep-daily 7"
  #     "--keep-weekly 5"
  #     "--keep-monthly 12"
  #   ];
  #   exclude = [
  #     "/var/cache"
  #     "/home/*/.cache"
  #   ];
  #   timerConfig = {
  #     OnCalendar = [ "02:00" ];
  #     RandomizedDelaySec = "30m";
  #   };
  # };

  services.restic.backups.data2 = let
    kiliHost = "musi@${hosts.kili.address}";
    pokiHost = "musi@${hosts.poki.address}";
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
    backupPrepareCommand = "${pkgs.writeShellScript "wake-poki" ''
      ssh ${kiliHost} -i ${pokiKey} wakeonlan A0:B3:CC:E9:4C:9C || exit 1
      for _ in $(seq 60)
      do
        sleep 15
        ssh ${pokiHost} -i ${pokiKey} -o ConnectTimeout=10 true && break
      done
    ''}";
  };
}
