{ lib, pkgs, config, ... }:
let
  directusPort = 8055;
  d2zPort = 8056;
  common = import ../common.nix {};
in {
  services.directus.servers = {
    "pompeani.art" = {
      enable = true;
      settings = common.settings // {
        PORT = directusPort;
      };
      nginx = {
        enable = true;
        serverName = "edit.ppom.me";
        location = "/pompeani.art";
      };
    };
  };

  users.users."directus-pompeani.art".extraGroups = [ "postmaster" ];

  users.users."directus2zola-pompeani.art" = {
    isSystemUser = true;
    group = "directus2zola-pompeani.art";
  };
  users.groups."directus2zola-pompeani.art" = {};

  systemd.services."directus2zola-pompeani.art" = {
    enable = true;
    wantedBy = [ "multi-user.target" ];
    requires = [ "directus-pompeani.art.service" ];
    after = [ "directus-pompeani.art.service" ];
    path = with pkgs; [ nodejs git zola rsync openssh ];
    serviceConfig = {
      Slice = "system-directus.slice";
      User = "directus2zola-pompeani.art";
      Group = "directus2zola-pompeani.art";
      Environment = [
        "DIRECTUS_PORT=${builtins.toString directusPort}"
        "D2Z_PORT=${builtins.toString d2zPort}"
        "D2Z_SSH_KEY=${common.sshKey}"
        "D2Z_SSH_DEST=pompeani.art-uploader@akesi.ppom.me:/var/www/pompeani.art/"
      ];
      StateDirectory =            "directus2zola-pompeani.art";
      WorkingDirectory = "/var/lib/directus2zola-pompeani.art";
      ExecStartPre = [ (pkgs.writeScript "directus2zola-pompeani.art-prestart" ''
          #!${pkgs.runtimeShell}
          set -e
          rm -f node_modules package.json index.js
          cat ${config.services.directus.package}/lib/package.json | \
            ${pkgs.jq}/bin/jq \
              '.type = "module" | .main = "index.js"' \
            > package.json
          ln -s ${config.services.directus.package}/lib/node_modules/directus/node_modules ./node_modules
          cp ${./directus2zola.js} ./index.js
          [[ -e zola ]] || git clone https://framagit.org/ppom/pompeani.art.git zola
        '')
        (pkgs.writeScript "directus2zola-pompeani.art-prestart-wait-for-directus" ''
          #!${pkgs.runtimeShell}
          set -e
          for _ in $(seq 20)
          do
            sleep 5
            ${pkgs.curl}/bin/curl --fail --max-time 5 http://localhost:${toString directusPort}/server/health && break
          done
        '')
      ];
      ExecStart = "${pkgs.nodejs}/bin/node ./index.js";
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
}
