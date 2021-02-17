{ lib, pkgs, config, ... }:
with lib;                      
let
  cfg = config.services.languagetool;
  languagetoolPort = "${builtins.toString cfg.port}";
in {
  options.services.languagetool = {
    enable = mkEnableOption "languagetool";
    domain = mkOption {
      type = types.str;
    };
    port = mkOption {
      type = types.int;
      default = 8500;
    };
  };

  config = mkIf cfg.enable {
    users.users = {
      languagetool = {
        isSystemUser = true;
        home = "/var/lib/languagetool";
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
    services.nginx.virtualHosts."${cfg.domain}" = {
      locations = {
        "/" = {
          proxyPass = "http://localhost:${languagetoolPort}";
        };
      };
    };
  };
}
