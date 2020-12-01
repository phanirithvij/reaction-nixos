# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

let
  sshPort = 5554;
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
  users.users.ppom = {
    isNormalUser = true;
    extraGroups = [ "docker" "wheel" ]; # Enable ‘sudo’ for the user.
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    wget git lftp
    neovim 
    fd ripgrep exa
    htop iftop ctop
    moreutils
    docker-compose
    handbrake
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

  # Open ports in the firewall.
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [
    sshPort
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
    clientMaxBodySize = "0";
    # Enable all recommended settings
    recommendedTlsSettings = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
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
      #};
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

  # Jirafeau config <3
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

