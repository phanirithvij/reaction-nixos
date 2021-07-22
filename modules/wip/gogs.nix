{ lib, pkgs, config, ... }:
let
  domainName = "git.ppom.me";
  appPort = 9600;
{
  services.gogs = {
    enable = true;
    appName = "ppom's Gogs";
    cookieSecure = true;
    database.type = "sqlite3";
    domain = domainName;
    httpPort = appPort;
    rootUrl = "https://${domainName}/";
  };

  services.nginx.virtualHosts."${domainName}" = {
    forceSSL = true;
    enableACME = true;
    locations."/" = {
      proxyPass = "http://localhost:${toString appPort}";
    };
  };
}
