{ ... }:
{
  services.immich = {
    enable = true;
    database.enableVectors = false;
    mediaLocation = "/data/immich";
  };

  systemd.tmpfiles.rules = [
    "d /data/immich 0700 immich root - -"
  ];

  services.postgresqlBackup.databases = [ "immich" ];

  services.nginx.virtualHosts = {
    "img.ppom.me" = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://localhost:2283";
        proxyWebsockets = true;
      };
    };
  };
}
