{ config, pkgs, ... }:
let
  marvinIP = "192.168.1.13";
  generalConf = {
        # enable and force SSL with Let's Encrypt
        forceSSL = true;
        enableACME = true;
        locations = {
          "/" = {
            proxyPass = "http://${marvinIP}";
            proxyWebsockets = true;
          };
        };
      };
in {

  services.nginx.virtualHosts = {
      "accueil.babos.land" = generalConf;
      "babos.land" = generalConf;
      "bureau.babos.land" = generalConf;
      "djembe.babos.land" = generalConf;
      "kiosque.babos.land" = generalConf;
      "tribune.babos.land" = generalConf;
  };

  services.directus.servers."babos" = {
    enable = true;
    settings = (import ./edit.ppom.me/common.nix {}).settings // {
      EMAIL_FROM = "babos.land@ppom.me";
      PORT = 8058;
    };
    nginx = {
      enable = true;
      serverName = "babos.land";
      location = "/repertoire";
    };
  };

  users.users."directus-babos".extraGroups = [ "postmaster" ];
}
