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

    commonHttpConfig = ''
      log_format combinedwithhost '$host: '
                    '$remote_addr - $remote_user'
                    '[$time_local] '
                    '"$request" $status $body_bytes_sent '
                    '"$http_referer" "$http_user_agent"';

      access_log /var/log/nginx/access.log combinedwithhost;
    '';

    virtualHosts."akesi.ppom.me" = {
      enableACME = true;
      forceSSL = true;
      locations."/".root = pkgs.writeTextDir "index.html" ''
        Succeedly wiped /
      '';
    };

    virtualHosts."paris-loyers.fr" = {
      default = true;
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
    defaults.email = "paco@ecomail.io";
  };
}
