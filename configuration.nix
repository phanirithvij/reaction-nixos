# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

let
  sshPort = 5554;
  torPort = 143;
  jitsiDomain = "chat.ppom.me";
  localAddress = "192.168.1.2";
  publicAddress = "88.160.19.71";
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.editor = false;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.tmpOnTmpfs = true;

  fileSystems."/data" = {
    device = "/dev/mapper/vg_data-lv_data";
    fsType = "ext4";
  };

  networking.hostName = "musi"; # Define your hostname.
  networking.useDHCP = false;
  networking.interfaces.enp6s0.useDHCP = true;

  # Set your time zone.
  time.timeZone = "Europe/Paris";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "fr";
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users = {
    ppom = {
      isNormalUser = true;
      extraGroups = [ "docker" "wheel" ]; # Enable ‘sudo’ for the user.
    };
    uploader = {
      isNormalUser = true;
      home = "/home/uploader";
      group = "nginx";
      openssh.authorizedKeys.keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC+QKvUjiZ4MnIzGaWJjVevXyEc8Ja3aORPE+gSYgBGwVOPK5SR9oQPyeBFQWjRuY9HeCarKoCWC4X7n0yg1hcYmFs4U7Tm1eb179+YYXIW2KPZOLrVBrAWzNTUPhcToo1/zsnLmFKbU/Kn/lt0YHo0pfDfRE1mFi2ORIEtyqg6nCeZkcb5DfunXG6lEejTm41aDoxs3UjqSBStP0GmX5ReVENRUxo0UzPcW1ImXLhD5A2BcOXvbaUp1lMWVfqY28gbYVDMbYyqDfMA3+yacXKoQcUwgDC9tKKzaxWuuYs/y+vVM01aARK7ol++9f5b1205LNDRVzzUIezrDZsWcggclcCaeKFy2rOBsVHj4wuMp9+M4NWF0NKetJsFOkas4BNUJXhSuGrhtvVeqQBtgtSt6gH7hRmPp/NZpG7OniK2g7Zm/jFte8aOPNWZL0iKv2fLNdPkgdx63MjgVDu5L1Z7I6kIvTBIRluLnzoOdsEWBm/9y0SacCsyRJKA2kPXfmc= ao@sona" ];
      extraGroups = [];
    };
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    wget git lftp
    file srm lsof
    neovim tmux fzf
    fd ripgrep exa
    htop iftop ctop
    zip unzip
    moreutils parted
    docker-compose
    python3
    handbrake ffmpeg-full
    mkvtoolnix
    catimg
  ];

  # nvim aliases
  nixpkgs.overlays = [
    (self: super: {
      neovim = super.neovim.override {
        viAlias = true;
        vimAlias = true;
	configure = {
          packages.myVimPackage = with pkgs.vimPlugins; {
            start = [ vim-nix gruvbox ];
            opt = [ ];
  }; }; }; }) ];

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.openssh.ports = [ sshPort ];
  services.openssh.permitRootLogin = "no";
  # Mosh extension
  programs.mosh.enable = true;

  # Open ports in the firewall.
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [
    sshPort
    torPort
    80 443 # web
    4443 10000 # additional ports for Jitsi
  ];
  networking.firewall.allowedUDPPorts = [
    4443 10000 # additional ports for Jitsi
  ];

  # Fail2ban service
  services.fail2ban.enable = true;
  services.fail2ban.jails.sshd = ''
port = ${builtins.toString sshPort}
enabled = true
banaction = iptables-multiport
maxretry = 5
findtime = 1200
bantime = 2400
'';

  # Nginx
  services.nginx = {
    enable = true;
    enableReload = true;
    clientMaxBodySize = "15G";
    # Enable all recommended settings
    recommendedTlsSettings = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    # http {} Nextcloud recommandations
    # https://github.com/nextcloud/docker/blob/master/.examples/docker-compose/with-nginx-proxy/postgres/fpm/web/nginx.conf
    commonHttpConfig = ''
      default_type  application/octet-stream;
      log_format main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';
      set_real_ip_from  10.0.0.0/8;
      set_real_ip_from  172.16.0.0/12;
      set_real_ip_from  192.168.0.0/16;
      real_ip_header    X-Real-IP;
      upstream nextcloud-upstream {
        server localhost:12000;
      }
    '';
    appendConfig = ''
      worker_processes auto;
    '';

    # Hosts config
    virtualHosts = {
      #"ebooks.cmercier.fr" = {
        #forceSSL = true;
        #enableACME = true;
        #locations = {
          #"/" = {
            #proxyPass = "http://192.168.1.29:80";
          #};
        #};
      #"boxdeppom.ppom.me" = {
        #forceSSL = true;
        #enableACME = true;
        #locations = {
          #"/" = {
            #proxyPass = "http://192.168.1.254:80";
          #};
        #};
      #};

      "nuage.ppom.me" = {
        forceSSL = true;
        enableACME = true;
        root = "/data/nextcloud/html";
        extraConfig = ''
        add_header Referrer-Policy "no-referrer" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header X-Download-Options "noopen" always;
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-Permitted-Cross-Domain-Policies "none" always;
        add_header X-Robots-Tag "none" always;
        add_header X-XSS-Protection "1; mode=block" always;

        fastcgi_hide_header X-Powered-By;

        location = /robots.txt {
            allow all;
            log_not_found off;
            access_log off;
        }

        rewrite ^/.well-known/host-meta /public.php?service=host-meta last;
        rewrite ^/.well-known/host-meta.json /public.php?service=host-meta-json last;
        rewrite ^/.well-known/webfinger /public.php?service=webfinger last;

        location = /.well-known/carddav {
            return 301 $scheme://$host:$server_port/remote.php/dav;
        }
        location = /.well-known/caldav {
            return 301 $scheme://$host:$server_port/remote.php/dav;
        }

        # set max upload size
        client_max_body_size 10G;
        fastcgi_buffers 64 4K;

        # Enable gzip but do not remove ETag headers
        gzip on;
        gzip_vary on;
        gzip_comp_level 4;
        gzip_min_length 256;
        gzip_proxied expired no-cache no-store private no_last_modified no_etag auth;
        gzip_types application/atom+xml application/javascript application/json application/ld+json application/manifest+json application/rss+xml application/vnd.geo+json application/vnd.ms-fontobject application/x-font-ttf application/x-web-app-manifest+json application/xhtml+xml application/xml font/opentype image/bmp image/svg+xml image/x-icon text/cache-manifest text/css text/plain text/vcard text/vnd.rim.location.xloc text/vtt text/x-component text/x-cross-domain-policy;

        location / {
            rewrite ^ /index.php;
        }

        location ~ ^\/(?:build|tests|config|lib|3rdparty|templates|data)\/ {
            deny all;
        }
        location ~ ^\/(?:\.|autotest|occ|issue|indie|db_|console) {
            deny all;
        }

        location ~ ^\/(?:index|remote|public|cron|core\/ajax\/update|status|ocs\/v[12]|updater\/.+|oc[ms]-provider\/.+)\.php(?:$|\/) {
            fastcgi_split_path_info ^(.+?\.php)(\/.*|)$;
            set $path_info $fastcgi_path_info;
            try_files $fastcgi_script_name =404;
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
            fastcgi_param PATH_INFO $path_info;
            # fastcgi_param HTTPS on;

            # Avoid sending the security headers twice
            fastcgi_param modHeadersAvailable true;

            # Enable pretty urls
            fastcgi_param front_controller_active true;
            fastcgi_pass nextcloud-upstream;
            fastcgi_intercept_errors on;
            fastcgi_request_buffering off;
        }

        location ~ ^\/(?:updater|oc[ms]-provider)(?:$|\/) {
            try_files $uri/ =404;
            index index.php;
        }

        # Adding the cache control header for js, css and map files
        # Make sure it is BELOW the PHP block
        location ~ \.(?:css|js|woff2?|svg|gif|map)$ {
            try_files $uri /index.php$request_uri;
            add_header Cache-Control "public, max-age=15778463";
            add_header Referrer-Policy "no-referrer" always;
            add_header X-Content-Type-Options "nosniff" always;
            add_header X-Download-Options "noopen" always;
            add_header X-Frame-Options "SAMEORIGIN" always;
            add_header X-Permitted-Cross-Domain-Policies "none" always;
            add_header X-Robots-Tag "none" always;
            add_header X-XSS-Protection "1; mode=block" always;
            access_log off;
        }

        location ~ \.(?:png|html|ttf|ico|jpg|jpeg|bcmap|mp4|webm)$ {
            try_files $uri /index.php$request_uri;
            access_log off;
        }
        '';
      };

      "video.ppom.me" = {
        forceSSL = true;
        enableACME = true;
        locations = {
          "/" = {
            proxyPass = "http://localhost:8001";
            #return = "301 https://videold.ppom.me\$request_uri";
          };
        };
      };

      "ppom.me" = {
        # makes it the default host
        default = true;
        # enable and force SSL with Let's Encrypt
        forceSSL = true;
        enableACME = true;
        # locations
        locations = {
          "/" = {
            index = "index.html";
            root = "/var/www/musi";
          };
        };
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
            extraConfig = "autoindex on;";
            #extraConfig = '' fancyindex on; fancyindex_exact_size off; '';
          };
        };
      };

      "chat.ppom.me" = {
        forceSSL = true;
        enableACME = true;
      };
    };
  };

  # Let's Encrypt config
  security.acme = {
    acceptTerms = true;
    email = "paco@ecomail.io";
  };

  # Jitsi meet config
  services.jitsi-meet = {
    enable = true;
    hostName = "chat.ppom.me";
    nginx.enable = true;
  };
  services.jitsi-videobridge = {
    enable = true;
    openFirewall = true;
    nat = {
      localAddress = localAddress;
      publicAddress = publicAddress;
    };
  };

  # Nextcloud config
  # https://jacobneplokh.com/how-to-setup-nextcloud-on-nixos/
  # services.nextcloud = {
    # enable = true; package = pkgs.nextcloud20; hostName = "nuage.ppom.me"; https = true; 
    # autoUpdateApps = { enable = true; startAt = "05:00:00"; };
    # config = { overwriteProtocol = "https";
      # dbtype = "pgsql"; dbuser = "nextcloud"; dbhost = "/run/postgresql"; dbname = "nextcloud"; dbpassFile = "/var/nextcloud-db-pass";
      # adminpassFile = "/var/nextcloud-admin-pass"; adminuser = "admin"; }; };
  # systemd.services."nextcloud-setup" = { requires = ["postgresql.service"]; after = ["postgresql.service"]; };

  # Currently only for Nextcloud
  services.postgresql = {
    enable = true;

    ensureDatabases = [ "nextcloud" ];
    ensureUsers = [
     { name = "nextcloud"; ensurePermissions."DATABASE nextcloud" = "ALL PRIVILEGES"; }
    ];
  };

  # Vas-y je suis un fou
  services.tor = {
    enable = true;
    enableGeoIP = true;
    relay = {
      enable = true;
      role = "relay";
      port = torPort;
      nickname = "parpaing";
      bandwidthRate = 8 * 1024 * 1024; # 8 MB/s
      contactInfo = "parpaing@tuta.io";
    };
  };

  #services.nextcloud = {
    #hostname = "file2.ppom.me";
    #https = true;
    #maxUploadSize = "3G";
  #};

  # Docker
  virtualisation.docker.enable = true;

  # SMART daemon → disk health check
  services.smartd.enable = true;

  # Secondary services
  programs.iftop.enable = true;

  services.locate = {
    enable = true;
    interval = "daily";
    prunePaths = [ "/tmp" "/var/tmp" "/var/cache" "/var/lock" "/var/run" "/var/spool" "/var/lib/docker" ];
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.09"; # Did you read the comment?

  system.autoUpgrade.enable = true;
  system.autoUpgrade.allowReboot = false;
}

