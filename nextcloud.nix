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
      dav = {
        priority = 10;
        return = "301 /remote.php/dav/";
      };
      r404 = { return = "404"; };
    in {
      forceSSL = true;
      enableACME = true;
      locations = {
        "/.well-known/caldav" = dav;
        "/.well-known/carddav" = dav;

        "/" = {
          priority = 30;
          index = "index.php";
          proxyPass = "http://localhost:${app.port}";
        };
      };
      extraConfig = ''
        add_header Content-Security-Policy "" always;
        # HTTP response headers borrowed from Nextcloud `.htaccess`
        add_header Referrer-Policy                      "no-referrer"   always;
        # add_header X-Content-Type-Options             "nosniff"       always;
        add_header X-Download-Options                   "noopen"        always;
        add_header X-Frame-Options                      "SAMEORIGIN"    always;
        add_header X-Permitted-Cross-Domain-Policies    "none"          always;
        add_header X-Robots-Tag                         "none"          always;
        add_header X-XSS-Protection                     "1; mode=block" always;
        # Remove X-Powered-By, which is an information leak
        fastcgi_hide_header X-Powered-By;
      '';
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
