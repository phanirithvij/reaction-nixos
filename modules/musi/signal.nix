{ pkgs, ... }:
let
  unstable = import <nixos-unstable> {};
  serviceConfig = {
    Type = "simple";
    User = "pombot";
    Restart = "always";
    Environment = [
      "XDG_DATA_HOME=/var/lib/pombot"
      "XDG_RUNTIME_DIR=/run/pombot"
    ];
    StateDirectory = "pombot";
    RuntimeDirectory = "pombot";
    RuntimeDirectoryPreserve = true;
    StateDirectoryMode = 0700;
    RuntimeDirectoryMode = 0700;
    LockPersonality = true;
    NoNewPrivileges = true;
    PrivateDevices = true;
    PrivateMounts = true;
    PrivateTmp = true;
    PrivateUsers = true;
    ProcSubset = "pid";
    ProtectClock = true;
    ProtectControlGroups = true;
    ProtectHome = true;
    ProtectHostname = true;
    ProtectKernelLogs = true;
    ProtectKernelModules = true;
    ProtectKernelTunables = true;
    ProtectProc = "invisible";
    ProtectSystem = "strict";
    RemoveIPC = true;
    RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" ];
    RestrictNamespaces = true;
    RestrictSUIDSGID = true;
    SystemCallArchitectures = "native";
    SystemCallFilter = [ "@system-service" "~@privileged" ];
    UMask = "0077";
  };
in {

  users.users.pombot = {
    isSystemUser = true;
    group = "pombot";
  };
  users.groups.pombot = {};

  systemd.services.signal-daemon = {
    enable = true;
    description = "Signal client daemon";
    after = [ "network.target" ];
    serviceConfig = serviceConfig // {
      ExecStart = "${pkgs.signal-cli}/bin/signal-cli daemon --socket --receive-mode manual";
      LogNamespace = "short";
    };
  };

  environment.etc."systemd/journald@short.conf".text = ''
    [Journal]
    Storage=volatile
    MaxRetentionSec=5h
  '';

  systemd.services.pombot = {
    enable = true;
    description = "Pombot, view-once resender";
    wantedBy = ["multi-user.target"];
    requires = [ "signal-daemon.service" ];
    after = [ "signal-daemon.service" ];
    serviceConfig = serviceConfig // {
      ExecStart = "${unstable.callPackage ../../pkgs/pombot {}}/bin/pombot";
      EnvironmentFile = ["/var/secrets/pombot"];
    };
  };
}
