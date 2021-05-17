{ options, lib, pkgs, ... }:
with lib;
let
  domainName = "video.ppom.me";
  localPort = "8001";
  user = "streama";
  format = pkgs.formats.yaml {};
  configFile = format.generate "application.yaml" cfg.settings;

in {

  options.services.streama = {
    enable = mkEnableOption "enable the Streama server";

    settings = lib.mkOption {
      type = format.type;
      default = {};
      description = ''
        Configuration for Streama, see
        <link xlink:href="https://github.com/streamaserver/streama/blob/master/docs/sample_application.yml"/>
        and its wiki for supported values.
      '';
    };

    package = mkOption {
      type = types.package;
      default = pkgs.streama;
      description = "Which Streama package to use.";
      example = "pkgs.streama";
    };

    domainName = mkOption {
      type = types.str;
      description = "Domain you want to use";
    };

    localPort = mkOption {
      type = types.int;
      description = "Port to expose on the host. It should not be opened on the network, as Nginx acts as a reverse proxy";
      default = 8001;
    };

    movieDir = mkOption {
      type = types.str;
      description = "Path to your movie directory. You must also specify it in Streama's console.";
    };

    h2Path = mkOption {
      type = types.str;
      description = ''
        Path to the h2 database file.
        If changed, no directory will be automatically created.
      '';
      default = "/var/lib/streama/streama";
    };

  };

  config = let
    cfg = options.services.streama;
  in
  {
    services.streama.settings = {
      environments = {
        production = {
          dataSource = lib.mkDefault {
            driverClassName =  "org.h2.Driver";
            url = "jdbc:h2:${cfg.h2Path};MVCC=TRUE;LOCK_TIMEOUT=10000;DB_CLOSE_ON_EXIT=FALSE";
            username = "root";
            password = "";
          };
          server = {
            port = cfg.localPort;
          };
        };
      };
      streama = {
        regex = {
          movies = [
            "^(?<Name>.*)[._ ]\\(\\d{4}\\).*"
          ];
          shows = [
            "^(?<Name>.+)[._ ][Ss](?<Season>\\d{2})[Ee](?<Episode>\\d{2,3}).*" # example:  "House.MD.S03E04.h264.mp4"
            "^(?<Name>.+)[._ ](?<Season>\\d{1,2})x(?<Episode>\\d{2,3}).*"      # example:  "House.MD.03x04.h264.mp4"
            "^(?<Season>\\d{2})-(?<Episode>\\d{2,3})-(?<Name>.*?)-.*"          # example:  "02-05-Dr. House-Tanz_ums_Feuer-cineonws.mp4"
            "^(?<Name>.*?)(?<Episode>\\d{1,3})x(?<Season>\\d{2}).*"            # example:  "Castle4x06DaemonsWebdl480pOktober242011rC.mkv(jkuzt).mp4"
          ];
        };
      };
    };

    services.nginx.enable = true;
    services.nginx.virtualHosts."${domainName}" = {
      forceSSL = true;
      enableACME = true;
      locations = {
        "/" = {
          proxyPass = "http://localhost:${localPort}";
          proxyWebsockets = true;
        };
      };
      extraConfig = ''
        client_max_body_size ${cfg.maxBodySize};
      '';
    };

    users.users."${user}" = {
      isSystemUser = true;
      home = cfg.stateDir;
    };

    systemd.packages = [ cfg.package ];

    systemd.services.streama = {
      enable = true;
      description = "Streama server";
      after = ["network.target"];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        User = "streama";
        ExecStart = "${package}/bin/streama -c ${configFile}";
        StateDirectory = "streama";
      };
    };
  };
}
