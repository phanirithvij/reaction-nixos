{ lib, pkgs, ... }:
with lib;
let
  localPort = 8001;
  dbPath = "jdbc:h2:/var/lib/streama/streama;AUTO_SERVER=TRUE";
  jarFile = pkgs.fetchurl {
    url = "https://github.com/streamaserver/streama/releases/download/v1.10.4/streama-1.10.4.jar";
    sha256 = "sha256:0bnsnwimx1mdxq7jh8z5wg7wh0g8gixkb99qmi9pbm7lhfvil1x1";
  };
  # Can't use pkgs.formats.yaml
  # Because the first section uses 4-spaces indentation
  # and the second section uses 2-spaces indentation.
  # And that's required, but I don't know how to specify this
  # with nix (according to me, that's simply a malformed yaml)
  config = pkgs.writeText "application.yml" ''
    environments:
        production:
            dataSource:
                driverClassName: org.h2.Driver
                url: ${dbPath};MVCC=TRUE;LOCK_TIMEOUT=10000;DB_CLOSE_ON_EXIT=FALSE
                username: root
                password:
            server:
                port: ${builtins.toString localPort}
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

  services.nginx.enable = true;
  services.nginx.virtualHosts."video.ppom.me" = {
    forceSSL = true;
    enableACME = true;
    locations."/" = {
      proxyPass = "http://localhost:${builtins.toString localPort}";
      proxyWebsockets = true;
      extraConfig = ''
        add_header X-Content-Type-Options    "nosniff"       always;
        add_header X-Frame-Options           "DENY"          always;
        add_header X-XSS-Protection          "1; mode=block" always;
        add_header Content-Security-Policy "default-src 'none'; script-src 'self' 'unsafe-inline' cdn.quilljs.com; style-src 'self' 'unsafe-inline' cdn.quilljs.com; img-src 'self' image.tmdb.org; font-src 'self'; media-src 'self'; connect-src 'self'; form-action 'self'; base-uri 'none'; frame-ancestors 'none';";

        proxy_set_header X-Forwarded-Port $server_port;
        proxy_cookie_path / "/; Secure; SameSite=strict";
      '';
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
      StateDirectory = "streama";
      StateDirectoryMode = 0700;
      Restart = "on-success"; # If oom-killed
      ReadWritePaths = [ "/var/lib/streama" "/data/streama/uploads" ];
      LockPersonality = true;
      NoNewPrivileges = true;
      PrivateDevices = true;
      PrivateMounts = true;
      PrivateTmp = true;
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

  environment.systemPackages = [ pkgs.h2 ];

  nixpkgs.overlays = [
    (self: super: {
      h2 = super.callPackage ../../pkgs/h2 {};
    })
  ];

  systemd.services.streama-backup = {
    description = "Make a SQL backup file of the Streama DB";
    script = ''
      OUTPUT=/var/lib/streama/backup.sql
      ${pkgs.h2}/bin/h2tool.sh org.h2.tools.Script -url "${dbPath}" -user root -password "" -script $OUTPUT
      chmod 600 $OUTPUT
    '';
    startAt = "daily";
  };

  systemd.services.streama-clean-duplicates = {
    description = "Clean duplicate viewing statuses on Streama";
    # Additional parenthesis added in the nested SELECT because of this: https://groups.google.com/g/h2-database/c/dBeNlTTXz-U
    script = ''
      ${pkgs.h2}/bin/h2tool.sh org.h2.tools.RunScript -url "${dbPath}" -user root -password "" -script ${
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
    startAt = "daily";
  };
}
