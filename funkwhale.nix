{ lib, pkgs, config, ... }:
with lib;
{
  options.services.funkwhale = {
    enable = mkEnableOption "enable Funkwhale using Docker";

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
        image = "funkwhale/all-in-one:1.1";
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
          extraConfig = ''
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header X-Forwarded-Host $host:$server_port;
            proxy_set_header X-Forwarded-Port $server_port;
            proxy_redirect off;

            # websocket support
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection $connection_upgrade;

            client_max_body_size ${cfg.maxBodySize};
            proxy_pass http://localhost:${builtins.toString cfg.hostPort};
          '';
        };
      };
      extraConfig = ''
        # HSTS
        add_header Strict-Transport-Security "max-age=31536000";
        # Security header
        add_header Content-Security-Policy "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; font-src 'self' data:; object-src 'none'; media-src 'self' data:";
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
  };
}
