{ lib, pkgs, config, ... }:
{
  options.services.rustdesk-server = with lib; with types; {
    enable = mkEnableOption "enable RustDesk";

    package = mkPackageOption pkgs "rustdesk-server" {};

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Open the connection ports.
        TCP (21115, 21116, 21117, 21118, 21119)
        UDP (21116)
      '';
    };

    relayIP = mkOption {
      type = str;
      description = ''
        The public facing IP of the RustDesk relay
      '';
    };
  };

  config = let
    cfg = config.services.rustdesk-server;
    serviceDefaults = {
      enable = true;
      requiredBy = [ "rustdesk.target" ];
      serviceConfig = {
        Slice = "rustdesk.slice";
        User  = "rustdesk";
        Group = "rustdesk";
        Environment = [];
        WorkingDirectory = "/var/lib/rustdesk";
        StateDirectory   = "rustdesk";
        StateDirectoryMode = "0750";
        LockPersonality = true;
        NoNewPrivileges = true;
        PrivateDevices = true;
        PrivateMounts = true;
        PrivateTmp = true;
        PrivateUsers = true;
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
        RestrictNamespaces = true;
        RestrictSUIDSGID = true;
      };
    };
  in lib.mkIf cfg.enable {
    users.users.rustdesk = {
      description = "System user for RustDesk";
      isSystemUser = true;
      group = "rustdesk";
    };
    users.groups.rustdesk = {};

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ 21115 21116 21117 21118 21119 ];
    networking.firewall.allowedUDPPorts = lib.mkIf cfg.openFirewall [ 21116 ];

    systemd.slices.rustdesk = {
      enable = true;
      description = "Slice designed to contain RustDesk Signal & RustDesk Relay";
    };

    systemd.targets.rustdesk = {
      enable = true;
      description = "Target designed to group RustDesk Signal & RustDesk Relay";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
    };

    systemd.services.rustdesk-signal = lib.mkMerge [ serviceDefaults {
      serviceConfig.ExecStart = "${cfg.package}/bin/hbbs -r ${cfg.relayIP}";
    } ];

    systemd.services.rustdesk-relay = lib.mkMerge [ serviceDefaults {
      serviceConfig.ExecStart = "${cfg.package}/bin/hbbr";
    } ];
  };

  meta.maintainers = with lib.maintainers; [ ppom ];
}
