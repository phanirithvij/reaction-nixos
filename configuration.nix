# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

let
  sshPort = 5554;
in
{
  imports = [
    ./hardware-configuration.nix
    ./languagetool.nix
    ./minecraft.nix
    ./streama.nix
    ./nextcloud.nix
    ./jitsi.nix
    ./tor.nix
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
    marguerite = {
      isNormalUser = true;
      hashedPassword = "$6$XswnWW/UsZq7X/HG$tIrhDQCWH7IHvNmCxmOcsF87qXTQWhsJ5666aioHQ7jQdffdY0.pu/CQc/iIHsxdW4CMpzm3GHRDaqw1iu5NC1";
      extraGroups = [ "users" ];
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
            let g:mapleader = " "
            nnoremap <leader>h :nohlsearch<Bar>:echo<CR>
          '';
          packages.myVimPackage = with pkgs.vimPlugins; {
            start = [
              vim-nix
              vim-commentary
              vim-surround
              vim-repeat
              vim-fugitive
            ];
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
    80 443 # web
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
            extraConfig = "autoindex on;";
            #extraConfig = '' fancyindex on; fancyindex_exact_size off; '';
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
      };
    };
  };

  # Let's Encrypt config
  security.acme = {
    acceptTerms = true;
    email = "paco@ecomail.io";
  };

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

