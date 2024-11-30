{ pkgs, ... }:
let
  convertd = pkgs.callPackage ../../../pkgs/convertd {};

  runDir = "RUNTIME_DIRECTORY=/data/convertd";
  cnv = pkgs.writeShellApplication {
    name = "cnv";
    text = ''
      ${runDir}
      ${builtins.readFile ./cnv.sh}
    '';
  };
in {
  systemd.services.convertd = {
    enable = true;
    description = "Queue-controlled video converter";
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.handbrake ];
    serviceConfig = {
      Type = "simple";
      User = "media";
      Environment = [ runDir ];
      ExecStart = "${convertd}/bin/convertd";
      # Resource Limit
      CPUQuota = "200%";
      CPUWeight = 1;
      # Security
      NoNewPrivileges = true;
      CapabilityBoundingSet = "";
      ProtectSystem = "strict";
      ReadOnlyPaths = [ "/data/transit" "/data/user-uploads" ];
      ReadWritePaths = [ "/data/convertd" ];
      ProtectHome = true;
      PrivateTmp = true;
      PrivateDevices = true;
      ProtectHostname = true;
      ProtectClock = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectKernelLogs = true;
      ProtectControlGroups = true;
      RestrictAddressFamilies = [ "AF_UNIX" "AF_INET" "AF_INET6" ];
      RestrictNamespaces = true;
      LockPersonality = true;
      RestrictSUIDSGID = true;
      RemoveIPC = true;
      PrivateMounts = true;
    };
  };

  environment.systemPackages = [ cnv pkgs.handbrake ];
}
