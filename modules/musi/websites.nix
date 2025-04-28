{ config, pkgs, stdenv, lib, ... }:

let
  nginxPackage = (pkgs.nginx.override {
    modules = with pkgs.nginxModules; [
      # Add fancy index module
      fancyindex
      # subsFilter # doesn't compile on 22.05
    ];
  });
  nginxLogPath = "/var/log/nginx/access.log";

  nginxRealPath = "/etc/static/nginx/nginx.conf";
  nginxConfPath = "/etc/nginx/nginx.conf";
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
      # "ppom.me" = {
      #   # enable and force SSL with Let's Encrypt
      #   forceSSL = true;
      #   enableACME = true;
      #   locations = {
      #     "/" = {
      #       index = "index.html";
      #       root = "/var/www/musi";
      #       tryFiles = "$uri $uri.html $uri/ =404";
      #     };
      #   };
      #   extraConfig = ''
      #     # do not even try connecting by HTTP
      #     # add_header Strict-Transport-Security "max-age=31536000";
      #     # do not allow to be framed inside another website
      #     add_header X-Frame-Options "DENY";
      #     # only allow script and style handling if the MIME type is correct
      #     add_header X-Content-Type-Options "nosniff";
      #     # tell browsers to only send https://domain.name as Referer
      #     add_header Referrer-Policy "strict-origin";
      #     # CSP
      #     add_header Content-Security-Policy "default-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; frame-ancestors: 'none';";
      #   '';
      # };

      # "www.ppom.me" = {
      #   enableACME = true;
      #   extraConfig = ''
      #     # Standard redirection
      #     # Comment this line ↓ to resolve ACME challenge
      #     return 301 https://ppom.me;
      #   '';
      # };

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
          "/beaumonts/" = {
            index = "index.html";
            extraConfig = ''
              add_header Content-Security-Policy "";
              add_header X-Content-Type-Options "nosniff";
              add_header X-Frame-Options "DENY";
            '';
          };
        };
        extraConfig = ''
          # add_header Strict-Transport-Security "max-age=31536000";
          add_header Content-Security-Policy "default-src 'self' 'unsafe-inline'; frame-ancestors 'none'";
          add_header X-Content-Type-Options "nosniff";
          add_header X-Frame-Options "DENY";
        '';
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
    };

    # Proxy to SSH
    # streamConfig = ''
    #   server {
    #     listen 80;
    #     # server_name musi.ppom.me;
    #     proxy_pass localhost:22;
    #   }
    # '';
  };

  # Let's Encrypt config
  security.acme = {
    acceptTerms = true;
    defaults.email = "ppom" + "@" + "ecomail" + "." + "fr";
  };

  # Workaround for cache files being sometimes owned by nobody
  systemd.tmpfiles.rules = [
    "Z '/var/cache/nginx' 0750 ${config.services.nginx.user} ${config.services.nginx.group} -"
    "f /data/uploader/index.html 0755 root root - 'Hello!'"
  ];

  # systemd.services."acme-www.ppom.me" = {
  #   requires = [ "acme-www.ppom.me-post.service" ];
  #   before = [ "acme-www.ppom.me-post.service" ];
  #   serviceConfig = {
  #     ExecStartPre = [ "+${pkgs.writeShellScript "acme-www.ppom.me.pre.sh" ''
  #       set -x

  #       file=$(mktemp)
  #       chmod 644 $file
  #       sed 's%return 301 https://ppom.me;%#return 301 https://ppom.me;%' > $file < ${nginxRealPath}

  #       rm ${nginxConfPath}
  #       cp $file ${nginxConfPath}
  #       systemctl reload nginx
  #     ''}" ];
  #   };
  # };

  # # Can't put this as an ExecStartPost of acme-www.ppom.me.service
  # # because there is already one [here](/nix/store/izraszd1vi8fa40kaw0c28lhv4chnw7j-nixos-22.11/nixos/nixos/modules/security/acme/default.nix → L316)
  # # and it's not in a list.
  # systemd.services."acme-www.ppom.me-post" = {
  #   script = ''
  #       set -x
  #       rm ${nginxConfPath}
  #       ln -s ${nginxRealPath} ${nginxConfPath}
  #       systemctl reload nginx
  #   '';
  # };

  systemd.services."uploader-auto-delete" = {
    serviceConfig = {
      ExecStart = "${pkgs.callPackage ../../pkgs/older.go {}}/bin/older /data/uploader/d";
      User = "uploader";
    };
    startAt = "1:00";
  };

  # Prevent it from being garbage-collected between each nginx config change
  environment.systemPackages = [ pkgs.gixy ];
}
