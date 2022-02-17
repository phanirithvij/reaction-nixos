{ lib, pkgs, ... }:
with lib;
let
  domainName = "video.ppom.me";
  localPort = "8001";
  dbPath = "/var/lib/streama/streama";
  # FIXME impure: idk how to download it reliably
  jarFile = /data/streama/data/streama-1.10.4.jar;
  config = pkgs.writeText "application.yml" ''
    environments:
        production:
            dataSource:
                driverClassName:  'org.h2.Driver'
                url: jdbc:h2:${dbPath};MVCC=TRUE;LOCK_TIMEOUT=10000;DB_CLOSE_ON_EXIT=FALSE;AUTO_SERVER=TRUE
                username: root
                password:
            server:
                port: ${localPort}
    streama:
      regex:
        movies: ^(?<Name>.*)[._ ]\(\d{4}\).*
        shows:
          - ^(?<Name>.+)[._ ][Ss](?<Season>\d{2})[Ee](?<Episode>\d{2,3}).*
  '';
  workingDir = pkgs.linkFarm "streama-pwd" [
    { name = "application.yml"; path = config; }
    { name = "streama.jar"; path = jarFile; }
  ];
in {
  # Reverse proxy configuration
  services.nginx.enable = true;
  services.nginx.virtualHosts."${domainName}" = {
      forceSSL = true;
      enableACME = true;
      locations = {

        "/" = {
          proxyPass = "http://localhost:${localPort}";
          proxyWebsockets = true;
          extraConfig = ''
            add_header X-Content-Type-Options    "nosniff"       always;
            add_header X-Frame-Options           "DENY"          always;
            add_header X-XSS-Protection          "1; mode=block" always;
            # add_header Strict-Transport-Security "max-age=31536000";
            add_header Access-Control-Allow-Origin "https://video.ppom.me";
            proxy_set_header X-Forwarded-Port $server_port;
          '';
        };

        "/sub" = {
          return = "301 /sub/";
        };

        "/sub/" = {
          # Needs the subsFilter NGINX module
          root = "/data/streama/movies";
          extraConfig = ''
            # Remove the sub/ in the root dir
            rewrite ^/sub(/.*)$ $1 break;

            # Show the files
            fancyindex on;
            fancyindex_exact_size off;

            # Filter mkv/mp4/avi files
            subs_filter '<tr>.*<a href="[^"]*.(mp4|mkv|avi)".*</tr>' ' ' r;
          '';
        };
        "~ /sub/.*\\.(mp4|mkv|avi)" = {
          return = "403";
        };
      };
  };

  users.users.streama = {
    isSystemUser = true;
    group = "streama";
  };
  users.groups.streama = {};

  systemd.services.streama = {
    enable = true;
    description = "Streama, video streaming server";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {
      Type = "simple";
      User = "streama";
      WorkingDirectory = workingDir;
      ExecStart = ''
        ${pkgs.jre8_headless}/bin/java -jar streama.jar
      '';
      NoNewPrivileges = true;
      ProtectSystem = "strict";
      ReadWritePaths = [ "/var/lib/streama" ];
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
  systemd.services."streama-init" = {
    enable = true;
    description = "Ensures /var/lib/streama is fine";
    requiredBy = [ "streama.service" ];
    before = [ "streama.service" ];
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
    script = ''
      set -e
      DIR=/var/lib/streama
      [ -d "$DIR" ] || mkdir "$DIR"
      chown "streama" "$DIR"
      chmod 700 "$DIR"
    '';
  };

  environment.systemPackages = [ pkgs.h2 ];

  systemd.timers.streama-backup = {
    description = "Make a SQL backup file of the Streama DB";
    wantedBy = [ "timers.target" ];
    timerConfig.OnCalendar = "daily";
  };
  systemd.services.streama-backup = {
    description = "Make a SQL backup file of the Streama DB";
    script = ''
      OUTPUT=/var/lib/streama/backup.sql
      ${pkgs.h2}/bin/h2tool.sh org.h2.tools.Script -url "jdbc:h2:/var/lib/streama/streama;AUTO_SERVER=TRUE" -user root -password "" -script $OUTPUT
      chmod 600 $OUTPUT
    '';
  };

  systemd.timers.streama-clean-duplicates = {
    description = "Clean duplicate viewing statuses on Streama";
    wantedBy = [ "timers.target" ];
    timerConfig.OnCalendar = "daily";
  };
  systemd.services.streama-clean-duplicates = {
    description = "Clean duplicate viewing statuses on Streama";
    # Additional parenthesis added in the nested SELECT because of this: https://groups.google.com/g/h2-database/c/dBeNlTTXz-U
    script = ''
      ${pkgs.h2}/bin/h2tool.sh org.h2.tools.RunScript -url "jdbc:h2:/var/lib/streama/streama;AUTO_SERVER=TRUE" -user root -password "" -script ${
        pkgs.writeScript
        "streama-clean-updates-script"
        ''
          DELETE FROM viewing_status
          WHERE (user_id, video_id, last_updated) NOT IN (
            SELECT (user_id, video_id, MAX(last_updated))
            FROM viewing_status
            GROUP BY (video_id, user_id)
          );
        ''
      }
    '';
  };
}
