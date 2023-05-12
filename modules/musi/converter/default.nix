{ lib, pkgs, ... }:
let
  withRuntimeDirectory = str: ''
    RUNTIME_DIRECTORY=/data/convertd
    ${str}
  '';
  convertd = pkgs.writeShellApplication {
    name = "convertd";
    runtimeInputs = with pkgs; [ handbrake ];
    text = withRuntimeDirectory (builtins.readFile ./convertd.sh);
  };
  cnv = pkgs.writeShellApplication {
    name = "cnv";
    runtimeInputs = with pkgs; [];
    text = withRuntimeDirectory (builtins.readFile ./cnv.sh);
  };
in {
  systemd.services.convertd = {
    enable = true;
    description = "Queue-controlled video converter";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      User = "media";
      # WorkingDirectory = workingDir;
      ExecStart = ''
        ${convertd}/bin/convertd /data/convertd
      '';
      # Resource Limit
      CPUQuota = "200%";
      CPUWeight = 1;
      # Security
      NoNewPrivileges = true;
      ProtectSystem = "strict";
      ReadWritePaths = [ "/data/transit" "/data/convertd" ];
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

  environment.systemPackages = [ convertd cnv ];
}
