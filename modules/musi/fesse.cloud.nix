{ pkgs, ... }:
let 
  # unstable = import <nixos-unstable> {};
in {
  services.peertube = {
    enable = true;
    package = pkgs.peertube.overrideAttrs (final: prev: {
      patches = (if prev ? patches then prev.patches else []) ++ [
        ./peertube-random.patch
      ];
    });
    enableWebHttps = true;
    configureNginx = true;
    listenWeb = 443;
    localDomain = "fesse.cloud";
    user = "fesse";
    group = "fesse";
    database = {
      createLocally = true;
      name = "fesse";
      user = "fesse";
    };
    redis = {
      createLocally = true;
    };
    dataDirs = [
      "/data/user-uploads"
      "/data/fesse"
    ];
    secrets.secretsFile = "/var/secrets/fesse";
    settings = {
      federation.enabled = false;
      storage = {
          avatars = "/data/fesse/avatars/";
          bin = "/data/fesse/bin/";
          cache = "/data/fesse/cache/";
          captions = "/data/fesse/captions/";
          client_overrides = "/data/fesse/client_overrides/";
          logs = "/data/fesse/logs/";
          original_video_files = "/data/fesse/original_video_files/";
          plugins = "/data/fesse/plugins/";
          previews = "/data/fesse/previews/";
          redundancy = "/data/fesse/redundancy/";
          storyboards = "/data/fesse/storyboards/";
          streaming_playlists = "/data/fesse/streaming_playlists/";
          thumbnails = "/data/fesse/thumbnails/";
          tmp = "/data/fesse/tmp/";
          tmp_persistent = "/data/fesse/tmp_persistent/";
          torrents = "/data/fesse/torrents/";
          web_videos = "/data/fesse/web-videos/";
          well_known = "/data/fesse/well_known/";
      };
      smtp = {
        hostname = "mail.girofle.org";
        port = 465;
        username = "admin@fesse.cloud";
        from_address = "admin@fesse.cloud";
      };
      csp = {
        enabled = true;
        report_only = false;
      };
    };
    smtp.passwordFile = "/var/secrets/mail/admin@fesse.cloud";
  };

  services.postgresqlBackup.databases = [ "fesse" ];

  systemd.tmpfiles.rules = [
    "f /var/secrets/fesse 640 root fesse -"
    "d /data/fesse 700 fesse fesse -"
  ];

  # systemd.services.peertube.serviceConfig.ExecStart = lib.mkForce ["true"];
  # systemd.services.peertube.serviceConfig.ExecStartPre = lib.mkForce ["true"];

  users = {
    users.fesse = {
      isSystemUser = true;
      group = "fesse";
    };
    groups.fesse = {};
  };

  services.nginx.virtualHosts."fesse.cloud" = {
    forceSSL = true;
    enableACME = true;
  };
}
