{ lib, pkgs, config, ... }:
with lib;                      
let
  languagetoolPort = "8500";
  languagetoolDomain = "lang.ppom.me";
in {
  users.users = {
    languagetool = {
      isSystemUser = true;
      packages = with pkgs; [ adoptopenjdk-jre-bin ];
    };
  };
  systemd.services.languagetool = {
    enable = true;
    description = "Language Tool self-hosted server";
    after = ["network.target"];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      User = "languagetool";
      ExecStart = ''${pkgs.languagetool}/bin/languagetool-http-server --port ${languagetoolPort}  --allow-origin "*"'';
    };
  };
  services.nginx.virtualHosts."${languagetoolDomain}" = {
    forceSSL = true;
    enableACME = true;
    locations = {
      "/" = {
        proxyPass = "http://localhost:${languagetoolPort}";
      };
    };
  };
}
