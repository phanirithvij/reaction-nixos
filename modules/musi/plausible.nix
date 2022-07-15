{ config, pkgs, ... }:
let
  domain = "stats.ppom.me";
  port = 8000;
in {
  services.plausible = {
    enable = true;
    # default clickhouse settings
    # default postgres settings
    mail.email = "stats@ppom.me";
    adminUser = {
      activate = true;
      email = "paco@ecomail.io";
      passwordFile = "/var/secrets/plausible/adminPassword";
    };
    # default smtp settings
    server = {
      inherit port;
      baseUrl = "https://${domain}";
      secretKeybaseFile = "/var/secrets/plausible/frameworkSecret";
    };
    releaseCookiePath = "/var/secrets/plausible/releaseCookie";
  };

  services.nginx.virtualHosts."${domain}" = {
    forceSSL = true;
    enableACME = true;
    locations."/".proxyPass = "http://localhost:${builtins.toString port}";
  };
}

