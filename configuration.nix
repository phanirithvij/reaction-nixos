# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

let
  sshPort = 5554;
  torPort = 143;
  jitsiDomain = "chat.ppom.me";
  languagetoolDomain = "lang.ppom.me";
  localAddress = "192.168.1.2";
  publicAddress = "88.160.19.71";
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./languagetool.nix
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
      extraGroups = [ "docker" "wheel" "users" ]; # Enable ‘sudo’ for the user.
    };
    uploader = {
      isNormalUser = true;
      home = "/home/uploader";
      group = "nginx";
      openssh.authorizedKeys.keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC+QKvUjiZ4MnIzGaWJjVevXyEc8Ja3aORPE+gSYgBGwVOPK5SR9oQPyeBFQWjRuY9HeCarKoCWC4X7n0yg1hcYmFs4U7Tm1eb179+YYXIW2KPZOLrVBrAWzNTUPhcToo1/zsnLmFKbU/Kn/lt0YHo0pfDfRE1mFi2ORIEtyqg6nCeZkcb5DfunXG6lEejTm41aDoxs3UjqSBStP0GmX5ReVENRUxo0UzPcW1ImXLhD5A2BcOXvbaUp1lMWVfqY28gbYVDMbYyqDfMA3+yacXKoQcUwgDC9tKKzaxWuuYs/y+vVM01aARK7ol++9f5b1205LNDRVzzUIezrDZsWcggclcCaeKFy2rOBsVHj4wuMp9+M4NWF0NKetJsFOkas4BNUJXhSuGrhtvVeqQBtgtSt6gH7hRmPp/NZpG7OniK2g7Zm/jFte8aOPNWZL0iKv2fLNdPkgdx63MjgVDu5L1Z7I6kIvTBIRluLnzoOdsEWBm/9y0SacCsyRJKA2kPXfmc= ao@sona" ];
      extraGroups = [ "users" ];
    };
    joris = {
      isNormalUser = true;
      openssh.authorizedKeys.keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgQDMwm/SE3y5gBkp19toGlXzar1XQdH6n7WAdg458QFSk1m2PSFd3BhAmfI5GxIwNnWXBW8KPQzGx1wJ92oTXaCXP0CTMNKm/DM5AhGqYsp/he5GI9rQNlogFo35zc6nSFgrDTB/P/4JgkTK5QRAXlSjyet1UkxgOnejnDnK7gsTvw== joris@joris-4DV-Kraken" ];
    };
  };

  environment.systemPackages = with pkgs; [
    wget git lftp
    file srm lsof
    neovim tmux fzf
    fd ripgrep exa du-dust
    htop iftop ctop
    zip unzip
    moreutils parted
    lm_sensors
    docker-compose docui
    python3 pydf
    youtube-dl
    handbrake ffmpeg-full
    mkvtoolnix dos2unix
    catimg
    cpulimit
  ];

  nixpkgs.overlays = [
    (self: super: {
      neovim = super.neovim.override {
        viAlias = true;
        vimAlias = true;
        configure = {
          customRC = ''
            set number termguicolors
          '';
          packages.myVimPackage = with pkgs.vimPlugins; {
            start = [ vim-nix ];
            opt = [];
          };
        };
      };
    })
  ];

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.openssh.ports = [ sshPort ];
  services.openssh.permitRootLogin = "no";
  # Mosh extension (doesn't work: TODO)
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

  # Cron jobs
  services.cron = {
    enable = true;
    systemCronJobs = [
      ''*/5 * * * *      root    docker exec -u 33 nc_app php cron.php''
    ];
  };

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

      "nuage.ppom.me" = let
        dav = { return = "301 /remote.php/dav/"; };
      in {
        forceSSL = true;
        enableACME = true;
        locations = {
          "/.well-known/caldav" = dav;
          "/.well-known/carddav" = dav;
          "/" = {
            index = "index.php";
            proxyPass = "http://localhost:9000";
          };
        };
      };

      "video.ppom.me" = {
        forceSSL = true;
        enableACME = true;
        locations = {
          "/" = {
            proxyPass = "http://localhost:8001";
          };
        };
      };

      "write.ppom.me" = {
        forceSSL = true;
        enableACME = true;
        extraConfig = ''
          location ^~ /loleaflet {
            proxy_pass http://localhost:9980;
            proxy_set_header Host $host;
          }
          # WOPI discovery URL
          location ^~ /hosting/discovery {
            proxy_pass http://localhost:9980;
            proxy_set_header Host $host;
          }
          # Capabilities
          location ^~ /hosting/capabilities {
            proxy_pass http://localhost:9980;
            proxy_set_header Host $host;
          }
          # main websocket
          location ~ ^/lool/(.*)/ws$ {
            proxy_pass http://localhost:9980;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "Upgrade";
            proxy_set_header Host $host;
            proxy_read_timeout 36000s;
          }
          # download, presentation and image upload
          location ~ ^/lool {
            proxy_pass http://localhost:9980;
            proxy_set_header Host $host;
          }
          # Admin Console websocket
          location ^~ /lool/adminws {
            proxy_pass http://localhost:9980;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "Upgrade";
            proxy_set_header Host $host;
            proxy_read_timeout 36000s;
          }
        '';
      };

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

      "${jitsiDomain}" = {
        forceSSL = true;
        enableACME = true;
      };

      "${languagetoolDomain}" = {
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

  # Language Tool: see ./languagetool.nix
  services.languagetool = {
    enable = true;
    domain = "lang.ppom.me";
  };

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

