{ lib, pkgs, config, ... }:
let
  directusPort = 8057;
  d2zPort = 8059;
  common = import ../common.nix {};
in {
  services.directus.servers = {
    "leborddeleau" = {
      enable = true;
      settings = common.settings // {
        PORT = directusPort;
      };
      nginx = {
        enable = true;
        serverName = "edit.ppom.me";
        location = "/leborddeleau";
      };
    };
  };

  users.users."directus-leborddeleau".extraGroups = [ "postmaster" ];

  users.users."directus2zola-leborddeleau" = {
    isSystemUser = true;
    group = "directus2zola";
  };

  systemd.services."directus2zola-leborddeleau" = {
    enable = true;
    wantedBy = [ "multi-user.target" ];
    requires = [ "directus-leborddeleau.service" ];
    after = [ "directus-leborddeleau.service" ];
    path = with pkgs; [ curl nodejs git rsync openssh zola tailwindcss ];
    serviceConfig = {
      Slice = "system-directus.slice";
      User = "directus2zola-leborddeleau";
      Group = "directus2zola";
      StateDirectory =            "directus2zola-leborddeleau";
      WorkingDirectory = "/var/lib/directus2zola-leborddeleau";
      Restart = "always";
      RestartSec = "10s";
      RestartMaxDelaySec = "2h";
      RestartSteps = "20";
      LoadCredential = "ssh_key:${common.sshKey}";
      ExecStartPre = "${pkgs.writeShellApplication {
        name = "d2z-bdo-prestart";
        text = ''
          #!${pkgs.runtimeShell}
          set -e

          [[ -e zola ]] || git clone https://framagit.org/ppom/leborddeleau.git zola

          for _ in $(seq 20)
          do
            sleep 5
            curl --silent --show-error --fail --max-time 5 http://localhost:${toString directusPort}/server/health && break
          done
        '';
      }}/bin/d2z-bdo-prestart";
      ExecStart = "${pkgs.writeShellApplication {
        name = "d2z-bdo";
        text = ''
          set -e
          build() {
            git pull || (git reset --hard HEAD^ && git pull)
            zola build
            tailwindcss -i ./main.css -o ./public/css/main.css
            rsync \
              -az --delete \
              --rsh="ssh -i $CREDENTIALS_DIRECTORY/ssh_key" \
              ./public/ \
              musi-uploader@akesi.ppom.me:/var/www/static/bdo
          }

          cd zola

          # Start with a build
          build

          while true
          do
            # Wait for an HTTP request then build
            node -e 'require("http").createServer((_, res) => { res.end("ok"); process.exit(); }).listen(${toString d2zPort})'
            build
          done
        '';
      }}/bin/d2z-bdo";
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
