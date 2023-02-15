{ config, pkgs, ... }:

let
  nginxPackage = (pkgs.nginx.override {
    modules = with pkgs.nginxModules; [
      # Add fancy index module
      fancyindex
      # subsFilter # doesn't compile on 22.05
    ];
  });
  nginxLogPath = "/var/log/nginx/access.log";
  reloadScript = pkgs.writeScript "custom-reload-acme-www-ppom-me" ''
    #!/${pkgs.runtimeShell}

    real_path=/etc/static/nginx/nginx.conf
    conf_path=/etc/nginx/nginx.conf

    set -x

    file=$(mktemp)
    chmod 644 $file
    sed 's%return 301 https://ppom.me;%#return 301 https://ppom.me;%' > $file < $real_path

    rm $conf_path
    cp $file $conf_path
    systemctl reload nginx
    systemctl start acme-www.ppom.me
    sleep 20
    rm $conf_path
    ln -s $real_path $conf_path
    systemctl reload nginx
  '';
in {
  networking.firewall.allowedTCPPorts = [
    80 443 # web
  ];

  # Nginx
  services.nginx = {

    package = nginxPackage;

    enable = true;
    enableReload = true;
    clientMaxBodySize = "15G";
    # Enable all recommended settings
    recommendedTlsSettings = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    appendConfig = ''
      worker_processes auto;
    '';
    commonHttpConfig = ''
      log_format withhost '$remote_addr - $remote_user [$time_local] '
                       '$host '
                       '"$request" $status $bytes_sent '
                       '"$http_referer" "$http_user_agent"';
      access_log ${nginxLogPath} withhost;
    '';

    # Hosts config
    virtualHosts = {
      "ppom.me" = {
        # enable and force SSL with Let's Encrypt
        forceSSL = true;
        enableACME = true;
        locations = {
          "/" = {
            index = "index.html";
            root = "/var/www/musi";
            tryFiles = "$uri $uri.html $uri/ =404";
          };
        };
        extraConfig = ''
          # do not even try connecting by HTTP
          # add_header Strict-Transport-Security "max-age=31536000";
          # do not allow to be framed inside another website
          add_header X-Frame-Options "DENY";
          # only allow script and style handling if the MIME type is correct
          add_header X-Content-Type-Options "nosniff";
          # tell browsers to only send https://domain.name as Referer
          add_header Referrer-Policy "strict-origin";
          # CSP
          add_header Content-Security-Policy "default-src 'self'; frame-ancestors: 'none';";
        '';
      };

      "www.ppom.me" = {
        # makes it the default host
        default = true;
        enableACME = true;
        extraConfig = ''
          # Redirection for Véloc
          if ($host = veloc.ppom.me) {
            return 301 https://assos.utc.fr/veloc/$request_uri;
          }
          # Standard redirection
          # Comment this line ↓ to resolve ACME challenge
          return 301 https://ppom.me;
        '';
      };

      "u.ppom.me" = {
        # enable and force SSL with Let's Encrypt
        forceSSL = true;
        enableACME = true;
        # locations
        root = "/data/uploader";
        locations = {
          "/" = {
            index = "index.html";
            extraConfig = ''
              fancyindex on;
              fancyindex_exact_size off;
            '';
          };
          "/QueeRcode/" = {
            index = "index.html";
            extraConfig = ''
              add_header Content-Security-Policy "default-src 'self' 'unsafe-inline'; frame-ancestors 'none';";
              add_header X-Content-Type-Options "nosniff";
              add_header X-Frame-Options "DENY";
            '';
          };
        };
        extraConfig = ''
          # add_header Strict-Transport-Security "max-age=31536000";
          add_header Content-Security-Policy "default-src 'self'; frame-ancestors 'none'; style-src 'self' 'unsafe-inline'";
          add_header X-Content-Type-Options "nosniff";
          add_header X-Frame-Options "DENY";
        '';
      };

      "xn--og8ha.ml" = {
        locations = {
          "/" = {
            index = "index.html";
            root = "/var/www/rainbow";
          };
        };
      };

      "veloc.ppom.me" = {
        extraConfig = ''
            return 301 https://assos.utc.fr/veloc/$request_uri;
        '';
        # enable and force SSL with Let's Encrypt
        forceSSL = true;
        enableACME = true;
      };

      "music.ppom.me" = {
        locations = {
          "/to" = {
            root = pkgs.fetchFromGitLab {
              domain = "framagit.org";
              owner = "ppom";
              repo = "funkwhale.to";
              rev = "7184399d62cb7ccae16354ac4126938ce63adaa8";
              sha256 = "sha256-NzPA5xJB04IQ9n9+dpMYSI7k9VKORgbdZyjyPiyVL1M=";
            };
            index = "index.html";
          };
        };
        forceSSL = true;
        enableACME = true;
      };

      "blog.ppom.me" = {
        # enable and force SSL with Let's Encrypt
        forceSSL = true;
        enableACME = true;
        # locations
        locations = {
          "/" = {
            tryFiles = "$uri $uri.html $uri/ =404";
            root = "/data/blog";
          };
        };
        extraConfig = ''
          # add_header Strict-Transport-Security "max-age=31536000";
          add_header Content-Security-Policy "default-src 'self' u.ppom.me; img-src 'none'; script-src 'unsafe-inline'; style-src 'unsafe-inline'; frame-ancestors 'none'; base-uri 'none'; form-action 'none'";
          add_header X-Content-Type-Options "nosniff";
          add_header X-Frame-Options "DENY";
        '';
      };

      "tokipona.ppom.me" = {
        # enable and force SSL with Let's Encrypt
        forceSSL = true;
        enableACME = true;
        # locations
        locations = {
          "/" = {
            tryFiles = "$uri $uri.html $uri/ =404";
            root = "/data/tokipona";
          };
        };
        extraConfig = ''
          # add_header Strict-Transport-Security "max-age=31536000";
          # add_header Content-Security-Policy "default-src 'self' u.ppom.me; img-src 'none'; script-src 'unsafe-inline'; style-src 'unsafe-inline'; frame-ancestors 'none'; base-uri 'none'; form-action 'none'";
          add_header X-Content-Type-Options "nosniff";
          add_header X-Frame-Options "DENY";
        '';
      };
    };
  };

  # Let's Encrypt config
  security.acme = {
    acceptTerms = true;
    defaults.email = "paco@ecomail.io";
  };

  # Workaround for cache files being sometimes owned by nobody
  systemd.tmpfiles.rules = [
    "Z '/var/cache/nginx' 0750 ${config.services.nginx.user} ${config.services.nginx.group} -"
    "f /data/uploader/index.html 0755 root root - 'Hello!'"
  ];

  systemd.services.custom-reload-acme-www-ppom-me = {
    description = "Temporarily edit the nginx conf to update properly the Let's Encrypt certificate for www.ppom.me";
    serviceConfig = {
      ExecStart = reloadScript;
    };
    startAt = "*-*-01 00:00:00";
  };

  systemd.services."acme-www.ppom.me".serviceConfig.OnFailure = "custom-reload-acme-www-ppom-me";

  # Can't make it work, hard to debug why
  # environment.etc."fail2ban/filter.d/nginx.conf".text = ''
  #     [INCLUDES]
  #     before = common.conf

  #     [Definition]
  #     failregex = ^<HOST>.*"(GET|POST).*" (404|444|403|400) .*$
  #     ignoreregex =
  #     # Due to systemd backend as a default, we have to set this as polling
  #     # (auto doesn't work when systemd is default backend)
  #     backend = polling
  #     logpath = ${nginxLogPath}
  # '';
  # services.fail2ban.jails.nginx = ''
  #     enabled = true
  #     port = 80,443
  #     filter = nginx

  #     maxretry = 40
  #     findtime = 60
  #     bantime = 7200
  # '';

  # services.fail2ban.jails.nginx-http-auth = ''
  #     enabled = true
  #     port = 80,443
  #     filter = nginx-http-auth
  #     # Due to systemd backend as a default, we have to set this as polling
  #     # (auto doesn't work when systemd is default backend)
  #     backend = polling
  #     logpath = ${nginxLogPath}

  #     maxretry = 5
  #     findtime = 60
  #     bantime = 7200
  # '';

}
