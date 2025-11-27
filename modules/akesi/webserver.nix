{
  lib,
  config,
  pkgs,
  ...
}:
let
  host =
    {
      root ? null,
      return ? null,
      extra ? { },
      csp ? { },
    }:
    let
      csp' = {
        "default-src" = [
          "'self'"
          "u.ppom.me"
          "static.ppom.me"
        ];
        "img-src" = [ "'self'" ];
        "script-src" = [
          "'self'"
          "'unsafe-inline'"
        ];
        "style-src" = [
          "'self'"
          "'unsafe-inline'"
        ];
        "frame-ancestors" = [ "'self'" ];
        "base-uri" = [ "'none'" ];
        "form-action" = [ "'none'" ];
      }
      // csp;
    in
    assert (root == null && return != null) || (return == null && root != null);
    {
      enableACME = true;
      forceSSL = true;
      locations = {
        "/" =
          (
            if root != null then
              {
                root = root;
                index = "index.html";
                tryFiles = "$uri $uri.html $uri/ =404";
                extraConfig = ''
                  proxy_intercept_errors on;
                  error_page 404 /404.html;
                '';
              }
            else
              {
                inherit return;
              }
          )
          // extra;
      };
      extraConfig = ''
        add_header Referrer-Policy "strict-origin";
        add_header X-Content-Type-Options "nosniff";
        add_header Content-Security-Policy "${
          builtins.concatStringsSep " " (
            lib.mapAttrsToList (name: values: "${name} ${builtins.concatStringsSep " " values};") csp'
          )
        }";
      '';
    };
in
{
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  services.nginx = {
    enable = true;
    enableReload = true;
    recommendedTlsSettings = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;

    package = (
      pkgs.nginx.override {
        modules = with pkgs.nginxModules; [
          fancyindex
        ];
      }
    );

    virtualHosts = {

      "akesi.ppom.me" = host { root = pkgs.writeTextDir "index.html" "Succeedly wiped /"; };

      "ppom.fr" = host { root = "/var/www/ppom.fr"; };

      "www.ppom.fr" = host { return = "301 https://ppom.fr$request_uri"; };

      "cours.ppom.fr" = lib.mkMerge [
        (host {
          root = "/var/www/cours.ppom.fr";
          csp = {
            "script-src" = [
              "'self'"
              "'unsafe-inline'"
              "'wasm-unsafe-eval'" # asciinema script
            ];
          };
        })
        {
          forceSSL = lib.mkForce false;
          addSSL = true;
          extraConfig = ''
            charset utf-8;
          '';
        }
      ];

      "lili-bel.com" = host { root = "/var/www/lili-bel.com"; };

      "www.lili-bel.com" = host { return = "301 https://lili-bel.com$request_uri"; };

      "leborddeleau.net" = host { root = "/var/www/leborddeleau.net"; };

      "www.leborddeleau.net" = host { return = "301 https://leborddeleau.net$request_uri"; };
      "www.lebordeleau.net" = host { return = "301 https://leborddeleau.net$request_uri"; };
      "lebordeleau.net" = host { return = "301 https://leborddeleau.net$request_uri"; };

      "paris-loyers.fr" = host {
        root = "/var/www/paris-loyers.fr";
        extra = {
          extraConfig = ''
            fancyindex on;
            fancyindex_exact_size off;
          '';
        };
      };

      "static.ppom.me" = host {
        root = "/var/www/static";
        extra = {
          extraConfig = ''
            fancyindex on;
            fancyindex_exact_size off;
          '';
        };
      };

      "blog.ppom.me" = host { root = "/var/www/blog"; };

      "tokipona.ppom.me" = host { root = "/var/www/tokipona"; };

    };
  };

  # Prevent it from being garbage-collected between each nginx config change
  environment.systemPackages = [ pkgs.gixy ];

  # Let's Encrypt config
  security.acme = {
    acceptTerms = true;
    defaults.email = "ppom" + "@" + "ecomail" + "." + "fr";
  };
}
