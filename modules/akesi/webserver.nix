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
      enableACME = true;
      forceSSL = true;
      locations."/".root = pkgs.writeTextDir "index.html" ''
        Succeedly wiped /
      '';
    };

    virtualHosts."ppom.fr" = {
      forceSSL = true;
      enableACME = true;
      locations = {
        "/" = {
          index = "index.html";
          root = "/var/www/ppom.fr";
          tryFiles = "$uri $uri.html $uri/ =404";
        };
      };
      extraConfig = ''
        # do not allow to be framed inside another website
        add_header X-Frame-Options "DENY";
        # only allow script and style handling if the MIME type is correct
        add_header X-Content-Type-Options "nosniff";
        # tell browsers to only send https://domain.name as Referer
        add_header Referrer-Policy "strict-origin";
        # CSP
        # add_header Content-Security-Policy "default-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline'; img-src 'self'; frame-src 'none'; frame-ancestors 'none'; base-uri 'none'";
      '';
    };
    virtualHosts."www.ppom.fr" = {
      enableACME = true;
      forceSSL = true;
      locations."/".return = "301 https://ppom.fr$request_uri";
    };

    virtualHosts."paris-loyers.fr" = {
      enableACME = true;
      forceSSL = true;
      locations."/".root = "/var/www/paris-loyers.fr";
    };
  };

  # Prevent it from being garbage-collected between each nginx config change
  environment.systemPackages = [ pkgs.gixy ];

  # Let's Encrypt config
  security.acme = {
    acceptTerms = true;
    defaults.email = "ppom" + "@" + "ecomail" + "." + "fr";
  };
}
