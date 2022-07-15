{ config, pkgs, ... }:
let
  nextcloud = {
    dockerName = "nc_app";
    domainName = "nuage.ppom.me";
    port = "7000";
  };
  # collabora = {
  #   dockerName = "collabora";
  #   domainName = "write.ppom.me";
  #   port = "9980";
  # };
  composeGeneration = import ./docker-compose.nix;
in {
  environment.etc."generated/nextcloud-suite/docker-compose.yml".source = (composeGeneration {
    # inherit nextcloud collabora;
    inherit nextcloud;
    toYaml = pkgs.toYaml;
  });
  environment.etc."generated/nextcloud-suite/coolwsd.xml".source = ./coolwsd.xml;

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

    # "${collabora.domainName}" =
    #   let 
    #     normalProxy = {
    #       proxyPass = "http://localhost:${collabora.port}";
    #     };
    #     wsProxy = {
    #       proxyPass = "http://localhost:${collabora.port}";
    #       proxyWebsockets = true;
    #       extraConfig = "proxy_read_timeout 36000s;";
    #     };
    #   in {
    #   forceSSL = true;
    #   enableACME = true;
    #   locations = {
    #     "^~ /browser" =              normalProxy;
    #     "^~ /hosting/discovery" =    normalProxy;
    #     "^~ /hosting/capabilities" = normalProxy;
    #     "~ ^/cool/(.*)/ws$" =        wsProxy;
    #     "~ ^/(c|l)ool" =             normalProxy;
    #     "^~ /cool/adminws" =         wsProxy;
    #   };
    # };
  };

  systemd.timers.nextcloud-run-cronjob = {
    wantedBy = [ "timers.target" ];
    after = [ "network.target" ];
    timerConfig.OnCalendar = "*-*-* *:0/5:0";
  };
  systemd.services.nextcloud-run-cronjob = {
    description = "Launch Nextcloud's regular job";
    serviceConfig.ExecStart = "${pkgs.docker}/bin/docker exec -u 33 ${nextcloud.dockerName} php cron.php";
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
      # Due to systemd backend as a default, we have to set this as polling
      # (auto doesn't work when systemd is default backend)
      backend = polling
      logpath = /data/nextcloud/html/data/nextcloud.log

      maxretry = 3
      bantime = 600
      findtime = 3600
    '';
  };

  virtualisation.docker.enable = true;
}
