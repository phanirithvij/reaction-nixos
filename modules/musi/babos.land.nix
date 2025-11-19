{ ... }:
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
    "compta.babos.land" = generalConf;
    "djembe.babos.land" = generalConf;
  };
}
