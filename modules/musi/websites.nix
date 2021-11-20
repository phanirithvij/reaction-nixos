{ config, pkgs, ... }:

{
  networking.firewall.allowedTCPPorts = [
    80 443 # web
  ];

  # Nginx
  services.nginx = {

    package = (pkgs.nginx.override {
      modules = with pkgs.nginxModules; [
        # Add fancy index module
        fancyindex
        subsFilter
      ];
    });

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
          # allow only certain types of ways to load content
          add_header Content-Security-Policy "default-src 'none'; img-src 'none'; script-src 'none'; style-src 'unsafe-inline'; frame-ancestors 'none'; base-uri 'none'; form-action 'none'";
          # do not allow to be framed inside another website
          add_header X-Frame-Options "DENY";
          # only allow script and style handling if the MIME type is correct
          add_header X-Content-Type-Options "nosniff";
          # tell browsers to only send https://domain.name as Referer
          add_header Referrer-Policy "strict-origin";
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
        locations = {
          "/" = {
            index = "index.html";
            root = "/data/uploader";
            # extraConfig = "autoindex on;";
            extraConfig = ''
              fancyindex on;
              fancyindex_exact_size off;
            '';
          };
        };
        extraConfig = ''
          # add_header Strict-Transport-Security "max-age=31536000";
          add_header Content-Security-Policy "default-src 'none'; img-src 'self'; script-src 'self'; style-src 'self'";
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
          add_header Content-Security-Policy "default-src 'none'; img-src 'none'; script-src 'none'; style-src 'unsafe-inline'; frame-ancestors 'none'; base-uri 'none'; form-action 'none'";
        '';
      };
    };
  };

  # Let's Encrypt config
  security.acme = {
    acceptTerms = true;
    email = "paco@ecomail.io";
  };

  # Workaround for cache files being sometimes owned by nobody
  systemd.tmpfiles.rules = [
    "Z '/var/cache/nginx' 0750 ${config.services.nginx.user} ${config.services.nginx.group} -"
  ];

}
