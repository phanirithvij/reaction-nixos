{ lib, config, pkgs, ... }:
{
  networking.firewall.allowedTCPPorts = [ 80 443 ];

  services.nginx = {
    enable = true;
    enableReload = true;
    recommendedTlsSettings = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;

    virtualHosts."akesi.ppom.me" = {
      default = true;
      enableACME = true;
      forceSSL = true;
      locations."/".root = pkgs.writeTextDir "index.html" ''
        Succeedly wiped /
      '';
    };

    virtualHosts."paris-loyers.fr" = {
      enableACME = true;
      forceSSL = true;
      locations."/".root = "/var/www/paris-loyers.fr";
    };
  };

  # Let's Encrypt config
  security.acme = {
    acceptTerms = true;
    defaults.email = "paco@ecomail.io";
  };
}
