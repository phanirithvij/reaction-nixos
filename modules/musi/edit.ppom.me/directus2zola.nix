{ lib, pkgs, config, ... }:
let
  common = import ./common.nix {};
  d2zPort = 8100;
  cfg = config.ppom.directus2zola;

  settingsFormat = pkgs.formats.json {};
  settingsFile = settingsFormat.generate "directus2zola.json" cfg.settings;

  package = pkgs.callPackage ../../../pkgs/directus2zola {};
in {

  options.ppom.directus2zola = {
    settings = lib.mkOption {
      default = {};
      description = "directus2zola settings";
      type = lib.types.submodule {
        freeformType = settingsFormat.type;
        options = {};
      };
    };
  };

  config = {
    ppom.directus2zola.settings = {
      port = d2zPort;
      ssh_key_file = "/run/credentials/directus2zola.service/ssh_key";
      state_directory = "/var/lib/directus2zola";
    };

    users.users."directus2zola" = {
      isSystemUser = true;
      group = "directus2zola";
      home = "/var/lib/directus2zola";
    };

    systemd.services.directus2zola = {
      enable = true;
      wantedBy = [ "multi-user.target" ];
      path = with pkgs; [ git zola rsync openssh ];
      serviceConfig = {
        Slice = "system-directus.slice";
        User = "directus2zola";
        Group = "directus2zola";
        LoadCredential = "ssh_key:${common.sshKey}";
        StateDirectory = "directus2zola";
        ExecStart = "${package}/bin/directus2zola ${settingsFile}";
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
  };
}
