{ config, pkgs, ... }:
let
  nextcloud = {
    dockerName = "nc_app";
    domainName = "nuage.ppom.me";
    port = "9000";
  };
  collabora = {
    dockerName = "collabora";
    domainName = "write.ppom.me";
    port = "9980";
  };
in {
  environment.etc."generated/nextcloud-suite/docker-compose.yml".source = ./docker-compose.nix {
    inherit nextcloud collabora;
    toYaml = pkgs.toYaml
  };

  # Reverse proxy config
  services.nginx.virtualHosts = {
    "${nextcloud.domainName}" = let
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
          proxyPass = "http://localhost:${nextcloud.port}";
        };
      };
      extraConfig = ''
        # add_header Strict-Transport-Security "max-age=31536000";
        add_header Content-Security-Policy "" always;
        # HTTP response headers borrowed from Nextcloud `.htaccess`
        add_header Referrer-Policy                      "no-referrer"   always;
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

  systemd.timers.nextcloud-run-cronjob = {
    wantedBy = [ "timers.target" ];
    after = [ "network.target" ];
    timerConfig.OnCalendar = "*-*-* *:*/5:0";
  };
  systemd.services.nextcloud-run-cronjob = {
    description = "Launch Nextcloud's regular job";
    serviceConfig.ExecStart = "docker exec -u 33 ${nextcloud.dockerName} php cron.php";
  };


  # Fail2ban
  environment.etc."fail2ban/filter.d/nextcloud.conf".text = ''
    [Definition]
    _groupsre = (?:(?:,?\s*"\w+":(?:"[^"]+"|\w+))*)
    failregex = ^\{%(_groupsre)s,?\s*"remoteAddr":"<HOST>"%(_groupsre)s,?\s*"message":"Login failed:
                ^\{%(_groupsre)s,?\s*"remoteAddr":"<HOST>"%(_groupsre)s,?\s*"message":"Trusted domain error.
    datepattern = ,?\s*"time"\s*:\s*"%%Y-%%m-%%d[T ]%%H:%%M:%%S(%%z)?"
  '';
  services.fail2ban = {
    enable = true;
    jails.nextcloud = ''
      enabled = true
      port = 80,443

      filter = nextcloud
      # Due to systemd backend as a default, we have to set this as pyinotify
      # (auto doesn't work when systemd is default backend)
      backend = pyinotify
      logpath = /data/nextcloud/html/data/nextcloud.log

      maxretry = 3
      bantime = 600
      findtime = 3600
    '';
  };

  virtualisation.docker.enable = true;
}
