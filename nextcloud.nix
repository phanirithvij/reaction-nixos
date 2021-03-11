{ config, pkgs, ... }:
let
  app = {
    dockerName = "nc_app";
    domainName = "nuage.ppom.me";
    port = "9000";
  };
  collabora = {
    dockerName = "collabora";
    domainName = "write.ppom.me";
    port = "9980";
  };
in
{
  # Reverse proxy config
  services.nginx.virtualHosts = {
    "${app.domainName}" = let
      dav = { return = "301 /remote.php/dav/"; };
    in {
      forceSSL = true;
      enableACME = true;
      locations = {
        "/.well-known/caldav" = dav;
        "/.well-known/carddav" = dav;
        "/" = {
          index = "index.php";
          proxyPass = "http://localhost:${app.port}";
        };
      };
    };

    "${collabora.domainName}" = {
      forceSSL = true;
      enableACME = true;
      extraConfig = ''
        location ^~ /loleaflet {
          proxy_pass http://localhost:${collabora.port};
          proxy_set_header Host $host;
        }
        # WOPI discovery URL
        location ^~ /hosting/discovery {
          proxy_pass http://localhost:${collabora.port};
          proxy_set_header Host $host;
        }
        # Capabilities
        location ^~ /hosting/capabilities {
          proxy_pass http://localhost:${collabora.port};
          proxy_set_header Host $host;
        }
        # main websocket
        location ~ ^/lool/(.*)/ws$ {
          proxy_pass http://localhost:${collabora.port};
          proxy_set_header Upgrade $http_upgrade;
          proxy_set_header Connection "Upgrade";
          proxy_set_header Host $host;
          proxy_read_timeout 36000s;
        }
        # download, presentation and image upload
        location ~ ^/lool {
          proxy_pass http://localhost:${collabora.port};
          proxy_set_header Host $host;
        }
        # Admin Console websocket
        location ^~ /lool/adminws {
          proxy_pass http://localhost:${collabora.port};
          proxy_set_header Upgrade $http_upgrade;
          proxy_set_header Connection "Upgrade";
          proxy_set_header Host $host;
          proxy_read_timeout 36000s;
        }
      '';
    };
  };

  # Cron jobs
  services.cron = {
    enable = true;
    systemCronJobs = [
      ''*/5 * * * *      root    docker exec -u 33 ${app.dockerName} php cron.php''
    ];
  };

  # TODO: docker config
  virtualisation.docker.enable = true;
}
