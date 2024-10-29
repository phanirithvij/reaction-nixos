{ lib, pkgs, config, ... }:
with lib;                      
let
  languagetoolPort = "8500";
  languagetoolDomain = "lang.ppom.me";
in {
  users.users.languagetool = {
    isSystemUser = true;
    group = "languagetool";
  };
  users.groups.languagetool = {};
  systemd.services.languagetool = {
    enable = true;
    description = "Language Tool self-hosted server";
    after = ["network.target"];
    # Low prio startup
    wantedBy = [ "multi-user3.target" ];
    serviceConfig = {
      Type = "simple";
      User = "languagetool";
      ExecStart = ''${pkgs.languagetool}/bin/languagetool-http-server --port ${languagetoolPort}  --allow-origin "*"'';
      NoNewPrivileges = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
      PrivateDevices = true;
      ProtectHostname = true;
      ProtectClock = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectKernelLogs = true;
      ProtectControlGroups = true;
      RestrictAddressFamilies = [ "AF_UNIX" "AF_INET" "AF_INET6" ];
      RestrictNamespaces = true;
      LockPersonality = true;
      RestrictSUIDSGID = true;
      RemoveIPC = true;
      PrivateMounts = true;
    };
  };
  services.nginx.virtualHosts."${languagetoolDomain}" = {
    forceSSL = true;
    enableACME = true;
    locations = {
      "/" = {
        proxyPass = "http://localhost:${languagetoolPort}";
        extraConfig = ''
          # add_header Strict-Transport-Security "max-age=31536000";
        '';
      };
    };
  };
}
