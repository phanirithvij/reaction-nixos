{ config, lib, pkgs, ... }:
let
  unstable = import <nixos-unstable> {};
  ocrs = pkgs.callPackage ../../pkgs/ocrs {};
  repo = "https://framagit.org/ppom/mememetadata.git";
  state = "/var/lib/compote";
  data = "/data/memes";
  json = pkgs.formats.json {};
  unix_socket = "/run/compote/compote.sock";
  configFile = json.generate "compote-config.json" {
    inherit unix_socket;
  };
in {
  users = {
    users = {
      compote = {
        isSystemUser = true;
        group = "memes";
      };
      ppom.extraGroups = [ "memes" ];
      uploader.extraGroups = [ "memes" ];
      anubis.extraGroups = [ "memes" ];
      nginx.extraGroups = [ "anubis" ];
    };
    groups.memes = {};
  };

  systemd.services = let
    commonSystemd = {
      User = "compote";
      Group = "memes";
      StateDirectory = "compote";
      ReadWritePaths = [ state data ];
      CapabilityBoundingSet = [ "" ];
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
      UMask = "0007";
    };
  in {

    compote-pre = {
      enable = true;
      description = "Meme metadata preparation";
      serviceConfig = commonSystemd // {
        Type = "oneshot";
        ReadWritePaths = lib.mkForce [];
        ExecStartPre = [
          "+${pkgs.coreutils}/bin/mkdir -p ${data}"
          "+${pkgs.coreutils}/bin/chmod 775 ${data}"
          "+${pkgs.coreutils}/bin/chown compote:memes ${data}"
        ];
        ExecStart = "${pkgs.writeShellApplication {
          name = "compote-pre";
          text = ''
            cd ${state}

            test -e tadata || \
              ${pkgs.git}/bin/git clone ${repo} tadata

            cd tadata

            test -e memes || \
              ln -sf ${data} memes

            ${pkgs.git}/bin/git pull

            ${pkgs.tailwindcss}/bin/tailwindcss \
              -i css/input.css -o css/tailwind.css
          '';
        }}/bin/compote-pre";
      };
    };

    compote = {
      enable = true;
      description = "Meme metadata";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" "compote-pre.service" ];
      requires = [ "compote-pre.service" ];
      serviceConfig = commonSystemd // {
        Type = "simple";
        WorkingDirectory = "${state}/tadata";
        ExecStart = "${unstable.sqlpage}/bin/sqlpage -c ${configFile}";
        RuntimeDirectory = "compote";
        RuntimeDirectoryMode = "0770";
      };
    };

    compote-cron = {
      enable = true;
      description = "Meme metadata cron";
      after = [ "compote-pre.service" ];
      requires = [ "compote-pre.service" ];
      startAt = "*:0/5";
      serviceConfig = commonSystemd // {
        Type = "oneshot";
        WorkingDirectory = "${state}/tadata";
        ExecStart = "${pkgs.writeShellApplication {
          name = "compote-cron";
          text = ''
            set -e
            export PATH=${ocrs}/bin:$PATH
            cd ${state}/tadata
            ${pkgs.git}/bin/git pull
            ${pkgs.tailwindcss}/bin/tailwindcss --watch \
              -i css/input.css -o css/tailwind.css
            ${unstable.deno}/bin/deno run \
              --allow-read=${state},${data} \
              --allow-write=${state},${data} \
              --allow-run=ocrs \
              scripts/cron.js

          '';
        }}/bin/compote-cron";
      };
    };
  };

  services.anubis = {
    instances.compote = {
      enable = true;
      settings = {
        SERVE_ROBOTS_TXT = true;
        SOCKET_MODE = "0770";
        TARGET = "unix://${unix_socket}";
      };
    };
  };

  services.nginx.virtualHosts = {
    "compote.ppom.me" = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://unix:${config.services.anubis.instances.compote.settings.BIND}";
      };
    };
  };
}
