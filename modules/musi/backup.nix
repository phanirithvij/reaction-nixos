{ config, ... }:
let
  hosts = builtins.fromTOML (builtins.readFile ../common/hosts.toml);
  kiliHost = "musi@${hosts.kili.address}";
  pokiHost = "musi@${hosts.poki.address}";
  pokiKey = "/var/secrets/backups/data2/sshkey";
in {
  services.postgresqlBackup = {
    enable = true;
    # every 6 hours, it only costs 2s of CPU time for now
    startAt = "*-*-* 0/6:15";
  };

  services.restic.backups.data2 = {
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
      OnCalendar = [ "05:00" ];
      # RandomizedDelaySec = "30m";
    };
  };

  systemd.services.wakepoki = {
    path = [ config.services.openssh.package ];
    script = ''
      ssh ${kiliHost} -i ${pokiKey} wakelan A0:B3:CC:E9:4C:9C || exit 0
      i=0
      while not ssh ${pokiHost} -i ${pokiKey} -o ConnectTimeout=10 true
      do
        i=$(($i + 1))
        test $i -lt 600 || exit 1
        sleep 5
      done
    '';
  };

  systemd.services.rebuild-poki = {
    requires = ["wakepoki.service"];
    after = ["wakepoki.service"];
  };
  
  systemd.services.restic-backups-data2 = {
    requires = ["wakepoki.service"];
    after = ["wakepoki.service"];

    serviceConfig = let
      systemctl = "${config.systemd.package}/bin/systemctl";
    in {
      # If it consumes too much RAM, let's kill it instead of crashing the server
      ManagedOOMMemoryPressure = "kill";
      # Limit CPU usage, maybe it will make the hardware fail less?
      CPUQuota = "250%";
      CPUWeight = 1;
      # Stop RAM hungry services before backup
      ExecStartPre = [
        "+${systemctl} stop slskd.service"
        "+${systemctl} reset-failed slskd.service"
        "+${systemctl} stop languagetool.service"
        "+${systemctl} reset-failed languagetool.service"
        "+${systemctl} stop streama.service"
        "+${systemctl} reset-failed streama.service"
      ];
      ExecStartPost = [
        "+${systemctl} start slskd.service"
        "+${systemctl} start languagetool.service"
        "+${systemctl} start streama.service"
      ];
    };
  };
}
