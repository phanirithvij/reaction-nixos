{ config, pkgs, ... }:

{
  networking.firewall.allowedTCPPorts = [
    80 443 # web
  ];

  # Nginx
  services.nginx = {

    additionnalModules = with pkgs.nginxModules; [
      # Add fancy index module
      fancyindex
    ];

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
        # makes it the default host
        default = true;
        # enable and force SSL with Let's Encrypt
        forceSSL = true;
        enableACME = true;
        locations = {
          "/" = {
            index = "index.html";
            root = "/var/www/musi";
          };
        };
        # Redirection for Véloc
        extraConfig = ''
          if ($host = veloc.ppom.me) {
            return 301 https://assos.utc.fr/veloc/$request_uri;
          } #
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
      };

      # "xn--morts_annonces-mkb.ppom.me" = {
      #   forceSSL = true;
      #   enableACME = true;
      #   locations = {
      #     "/" = {
      #       index = "/data/uploader/morts_annoncees.mp4";
      #       root = "/var/empty";
      #     };
      #   };
      # };

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
      };
    };
  };

  # Let's Encrypt config
  security.acme = {
    acceptTerms = true;
    email = "paco@ecomail.io";
  };

}
