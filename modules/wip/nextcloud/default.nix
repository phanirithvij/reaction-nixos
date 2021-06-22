{ config, pkgs, ... }:
let
  composeFile = pkgs.callPackage ./docker-compose.yml.nix { inherit pkgs; };
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
        add_header Strict-Transport-Security "max-age=31536000";
        add_header Content-Security-Policy "" always;
        # HTTP response headers borrowed from Nextcloud `.htaccess`
        add_header Referrer-Policy                      "no-referrer"   always;
        # Remove X-Powered-By, which is an information leak
        fastcgi_hide_header X-Powered-By;
      '';
    };

    "${collabora.domainName}" = 
    let
      base = ''
          proxy_pass http://localhost:${collabora.port};
          proxy_set_header Host $host;
      '';
      websocket = ''
          proxy_set_header Upgrade $http_upgrade;
          proxy_set_header Connection "Upgrade";
          proxy_read_timeout 36000s;
      '';
    in {
      forceSSL = true;
      enableACME = true;
      extraConfig = ''
        location ^~ /loleaflet {
          ${base}
        }
        # WOPI discovery URL
        location ^~ /hosting/discovery {
          ${base}
        }
        # Capabilities
        location ^~ /hosting/capabilities {
          ${base}
        }
        # main websocket
        location ~ ^/lool/(.*)/ws$ {
          ${base}
          ${websocket}
        }
        # download, presentation and image upload
        location ~ ^/lool {
          ${base}
        }
        # Admin Console websocket
        location ^~ /lool/adminws {
          ${base}
          ${websocket}
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

  # Fail2ban
  # Not sure whether it is effective or not.
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
      protocol = tcp
      filter = nextcloud
      maxretry = 3
      bantime = 600
      findtime = 3600
      logpath = /data/nextcloud/html/data/nextcloud.log
    '';
  };

  # systemd.services.docker-nextcloud-suite = {
  #   enable = true;
  #   description = "Nextcloud, PostgreSQL and Collabora in a Nix managed docker-compose";
  #   after = ["network.target"];
  #   wantedBy = [ "multi-user.target" ];
  #   serviceConfig = {
  #     Type = "forking";
  #     User = "root";
  #     ExecStart = ''${pkgs.docker-compose}/bin/docker-compose -f ${composeFile} -p nc up -d'';
  #     ExecStop  = ''${pkgs.docker-compose}/bin/docker-compose -f ${composeFile} -p nc down'';
  #   };
  # };

  # TODO: docker config → replace docker-compose with Nix
  virtualisation.docker.enable = true;
}
