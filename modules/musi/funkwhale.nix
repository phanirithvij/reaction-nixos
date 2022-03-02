{ lib, pkgs, config, ... }:
with lib;
{
  options.services.funkwhale = {
    enable = mkEnableOption "enable Funkwhale using Docker AIO container";

    domainName = mkOption {
      type = types.str;
      description = "Domain you want to use";
    };

    hostPort = mkOption {
      type = types.int;
      description = "Port to expose on the host";
      default = 8020;
    };

    musicDir = mkOption {
      type = types.str;
      description = "Path to your music directory";
    };

    envFile = mkOption {
      type = types.str;
      description = ''
        Env file which will store the Django secret key
        Example:
        ```
        DJANGO_SECRET_KEY=password!
        ```
      '';
    };

    dataDir = mkOption {
      type = types.str;
      description = "Path to the data directory. Can also be a docker volume";
      default = "funkwhale_data";
    };

    maxBodySize = mkOption {
      type = types.str;
      description = "Max upload size. Handled by nginx";
      default = "100M";
    };

    importCronEnable = mkEnableOption "Enable a daily job to update the library from disk";

    importCronLibraryID = mkOption {
      type = types.str;
      description = "ID of the library to import";
    };
  };

  config = let
    cfg = config.services.funkwhale;
    containerPort = "80";
  in mkIf cfg.enable {

    # Docker service configuration
    virtualisation = {
      docker.enable = true;
      oci-containers.containers.funkwhale = {
        autoStart = true;
        image = "funkwhale/all-in-one:1.1.4";
        ports = [ "${builtins.toString cfg.hostPort}:${containerPort}" ];
        volumes = [
          "${cfg.dataDir}:/data"
          "${cfg.musicDir}:/music:ro"
        ];
        environment = {
          FUNKWHALE_HOSTNAME = cfg.domainName;
          FUNKWHALE_PROTOCOL = "https";
          FUNKWHALE_API_IP = "127.0.0.1";
          FUNKWHALE_API_PORT = containerPort;
          FUNKWHALE_WEB_WORKERS = "4";
          NESTED_PROXY = "1";
          NGINX_MAX_BODY_SIZE = cfg.maxBodySize;
        };
        extraOptions = [
          # Only used to store the secret
          "--env-file=${cfg.envFile}"
        ];
      };
    };

    # Reverse proxy configuration
    services.nginx.enable = true;
    services.nginx.virtualHosts."${cfg.domainName}" = {
      forceSSL = true;
      enableACME = true;
      locations = {
        "/" = {
          proxyWebsockets = true;
          proxyPass = "http://localhost:${builtins.toString cfg.hostPort}";
          extraConfig = ''
            proxy_set_header X-Forwarded-Port $server_port;
            proxy_redirect off;

            client_max_body_size ${cfg.maxBodySize};
          '';
        };
      };
      extraConfig = ''
        # HSTS
        # add_header Strict-Transport-Security "max-age=31536000";
        # Security
        proxy_cookie_path / "/; Secure; SameSite=strict";
        # compression settings
        gzip on;
        gzip_comp_level    5;
        gzip_min_length    256;
        gzip_proxied       any;
        gzip_vary          on;
        gzip_types
            application/javascript
            application/vnd.geo+json
            application/vnd.ms-fontobject
            application/x-font-ttf
            application/x-web-app-manifest+json
            font/opentype
            image/bmp
            image/svg+xml
            image/x-icon
            text/cache-manifest
            text/css
            text/plain
            text/vcard
            text/vnd.rim.location.xloc
            text/vtt
            text/x-component
            text/x-cross-domain-policy;
      '';
    };

    systemd.timers.update-funkwhale-library = (lib.optionalAttrs cfg.importCronEnable {
      wantedBy = [ "timers.target" ];
      after = [ "network.target" ];
      timerConfig = {
        OnCalendar = "daily";
      };
    });
    systemd.services.update-funkwhale-library = (lib.optionalAttrs cfg.importCronEnable {
      description = "Update the funkwhale library in place";
      # faketty function found here: https://stackoverflow.com/questions/32910661
      script = ''
        faketty () {
          ${pkgs.util-linux}/bin/script -qefc "$(printf "%q " "$@")"
        }
        faketty ${pkgs.docker}/bin/docker exec -it funkwhale manage import_files ${cfg.importCronLibraryID} /music --in-place --async --recursive --noinput;
      '';
    });
    security.doas.extraRules = (lib.optionals cfg.importCronEnable [{
      users = [ "ppom" ];
      cmd = "systemctl";
      args = [ "start" "update-funkwhale-library.service" ];
      runAs = "root";
      noPass = true;
    }]);
  };
}
