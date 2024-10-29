{ lib, pkgs, config, ... }:
let 
in {
  services.peertube = {
    enable = true;
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
      storage = {
          tmp = "/data/fesse/tmp/";
          tmp_persistent = "/data/fesse/tmp_persistent/";
          bin = "/data/fesse/bin/";
          avatars = "/data/fesse/avatars/";
          web_videos = "/data/fesse/web_videos/";
          streaming_playlists = "/data/fesse/streaming_playlists/";
          redundancy = "/data/fesse/redundancy/";
          logs = "/data/fesse/logs/";
          previews = "/data/fesse/previews/";
          thumbnails = "/data/fesse/thumbnails/";
          storyboards = "/data/fesse/storyboards/";
          torrents = "/data/fesse/torrents/";
          captions = "/data/fesse/captions/";
          cache = "/data/fesse/cache/";
          plugins = "/data/fesse/plugins/";
          well_known = "/data/fesse/well_known/";
          client_overrides = "/data/fesse/client_overrides/";
      };
      smtp = {
        hostname = "mail.girofle.org";
        port = 465;
        username = "admin@fesse.cloud";
        from_address = "admin@fesse.cloud";
      };
    };
    smtp.passwordFile = "/var/secrets/mail/admin@fesse.cloud";
  };

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
