{ lib, pkgs, ... }:
let
  configPath = "/var/lib/mattermostgithub/config.py";
  mattermostgithub = pkgs.callPackage ../../pkgs/mattermost-github-integration { inherit configPath; };

  domainName = "ppom.me";
  path = "/GHBot";
  localPort = "4587";

  mattermostSecretPath = "/var/secrets/mattermostgithub/mattermost.secret";
  githubSecretPath = "/var/secrets/mattermostgithub/github.secret";
  config = {
    mattermost = "https://team.picasoft.net";
    username = "github";
    iconUrl = "https://u.ppom.me/github.png";
    channel = "mobiliportail";
  };

in {
  services.nginx.enable = true;
  services.nginx.virtualHosts."${domainName}" = {
      forceSSL = true;
      enableACME = true;
      locations."${path}" = {
        proxyPass = "http://localhost:${localPort}";
      };
  };

  users.users.mattermostgithub = {
    isSystemUser = true;
    group = "mattermostgithub";
  };
  users.groups.mattermostgithub = {};

  systemd.services.mattermostgithub = {
    enable = true;
    description = "GitHub integration for Mattermost";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {
      Type = "simple";
      User = "mattermostgithub";
      ExecStart = ''${mattermostgithub}/bin/mattermostgithub'';
      NoNewPrivileges = true;
      ProtectSystem = "strict";
      ReadWritePaths = [];
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

  systemd.services."mattermostgithub-init" = {
    enable = true;
    description = "Creates mattermostgithub config file";
    requiredBy = [ "mattermostgithub.service" ];
    before = [ "mattermostgithub.service" ];
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
    script = ''
      set -e
      DIR="$(dirname "${configPath}")"
      [ -d "$DIR" ] || mkdir "$DIR"
      chown mattermostgithub "$DIR"
      chmod 700 "$DIR"

      mattermostSecret="$(cat "${mattermostSecretPath}")"
      githubSecret="$(cat "${githubSecretPath}")"

      cat > "${configPath}" <<EOF
      USERNAME = "${config.username}"
      ICON_URL = "${config.iconUrl}"

      # Repository settings
      MATTERMOST_WEBHOOK_URLS = {
          'default' : ("${config.mattermost}/hooks/$mattermostSecret", "${config.channel}"),
      }

      # Ignore specified event actions
      GITHUB_IGNORE_ACTIONS = {
          "pull_request": ["synchronize"]
      }

      # Ignore events from specified users
      IGNORE_USERS = {
          # "someuser": ["push"],
          # "anotheruser": ["push", "create"]
      }

      # Redirect events to different channels
      REDIRECT_EVENTS = {
          # "push": "commits"
      }
      SECRET = "$githubSecret"
      SHOW_AVATARS = True
      SERVER = {
          'hook': "${path}",
          'address': "127.0.0.1",
          'port': ${localPort},
      }
      EOF
    '';
  };
}
