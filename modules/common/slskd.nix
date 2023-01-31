{ lib, pkgs, config, ... }:
{
  options.services.slskd = with lib; with types; {
    enable = mkEnableOption "enable slskd";

    package = mkOption {
      type = package;
      description = "The slskd package to use";
      default = pkgs.callPackage ../pkgs/slskd {};
    };

    nginx = mkOption {
      type = submodule;
      enable = mkEnableOption "enable nginx as a reverse proxy";

      domainName = mkOption {
        type = str;
        description = "Domain you want to use";
      };
    };

    musicDir = mkOption {
    };

    environmentFile = mkOption {
      type = path;
      description = ''
        Path to a file containing secrets.
        It must at least contain the variable `SLSKD_SLSK_PASSWORD`
      '';
    };

    openFirewall = mkOption {
      type = bool;
      description = ''
        Whether to open the firewall for services.slskd.settings.listen_port";
      '';
      default = false;
    };

    settings = mkOption {
      description = ''
        Configuration for slskd, see
        [available options](https://github.com/slskd/slskd/blob/master/docs/config.md)
      '';
      default = {};
      type = submodule {
        freeformType = settingsFormat.type;
        options = {

          soulseek = {
            username = mkOption {
              type = str;
              required = true;
              description = "Username on the Soulseek Network";
            };
            listen_port = mkOption {
              type = port;
              description = "Port to use for communication on the Soulseek Network";
              default = 50000;
            };
          };

          web = {
            port = mkOption {
              type = port;
              default = 5001;
              description = "The HTTP listen port";
            };
            url_base = mkOption {
              type = str;
              default = "/";
              description = "The base url for web requests";
            };
            content_path = mkOption {
              type = path;
              description = "The base url for web requests";
            };
          };

          shares = {
            directories = mkOption {
              type = listOf str;
              description = ''
                Paths to your shared directories. See
                [documentation](https://github.com/slskd/slskd/blob/master/docs/config.md#directories)
                for advanced usage'';
            };
          };

          directories = {
            # > Directories must exist and be writable by the application
            # TODO make a tmpfiles declaration
            incomplete = mkOption {
              type = path;
              description = "Directory where downloading files are stored";
              default = "/var/lib/slskd/incomplete";
            };
            downloads = mkOption {
              type = path;
              description = "Directory where downloading files are stored";
              default = "/var/lib/slskd/downloads";
            };
          };
        };
      };
    };

  };

  config = let
    cfg = config.services.slskd;
    settingsFormat = pkgs.formats.yaml {};
    configurationYaml = settingsFormat.generate "slskd.yml" cfg.settings;

  in lib.mkIf cfg.enable {

    users = {
      users.slskd = {
        isSystemUser = true;
        group = "slskd";
      };
      groups.slskd = {};
    };

    # Reverse proxy configuration
    services.nginx.enable = true;
    services.nginx.virtualHosts."${cfg.domainName}" = {
      forceSSL = true;
      enableACME = true;
      # TODO externalize static content
      # TODO use settings.web
      locations = {};
    };

    systemd.services.slskd = {
      description = "A modern client-server application for the Soulseek file sharing network";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        User = "slskd";
        EnvironmentFile = lib.mkIf (cfg.environmentFile != null) cfg.environmentFile;
        Environment = {
          APP_DIR = "/var/lib/slskd";
          # TODO log to systemd?
        };
        ExecStartPre = pkgs.writeScript "slskd-init.sh" ''
          mkdir -p /var/lib/slskd
          chown -R slskd:slskd /var/lib/slskd
          cp ${configurationYaml} /var/lib/slskd/slskd.yml
        '';
        ExecStart = "${pkgs.slskd}/bin/slskd";
        Restart = "on-failure";
        # TODO hardening
        # TODO allow only shares as RO and /var/lib/slskd and upload directories as RW
      };
    };
  };
}
