{ lib, config, pkgs, ... }:
{
  imports = [
      ../common

      ./direnv.nix
      ./down-detector.nix
      ./graphical.nix
      ./hardware-configuration.nix
      # ./nginx.nix
      ./packages.nix
      ./vpnc.nix
      # ./wireguard.nix
      # ./phpmysql.nix
      # ./userunits.nix
    ];

  ### Flavors

  specialisation = {
    # A (future) wifi proxy
    # withAccessPoint = {
    #   imports = [ ./accesspoint.nix ];
    # }
  };

  ### System ###

  # Boot
  boot = {
    loader.systemd-boot.enable = true;
    loader.systemd-boot.editor = false;
    loader.efi.canTouchEfiVariables = true;
    tmpOnTmpfs = true;
    # add ntfs support
    supportedFilesystems = [ "ntfs" ];
    # plymouth = { enable = true; logo = pkgs.fetchurl { url = "https://u.ppom.me/plymouth.png"; sha256 = "b2d44f5120e6528cec6dea9b6b8ad049e57b7f65670d8f05ca1c18b5a43c63d7"; }; };

    # The 5.15 mainline has a "dim brightness" bug for me
    kernelPackages = pkgs.linuxKernel.packages.linux_5_10;
  };

  # Networking
  networking = {
    hostName = "sona";

    # Per-interface useDHCP
    useDHCP = false;
    # interfaces.enp2s0.useDHCP = true;
    # interfaces.wlp9s0.useDHCP = true;

    # nameservers = [ "80.67.169.12" "80.67.169.40" ]; # FDN DNS. does not override provided DNS :(

    extraHosts = "10.62.215.188 y.local";

    networkmanager.enable = true;
    networkmanager.wifi.powersave = true;

    firewall = {
      enable = true;
      allowedTCPPorts = [
        5500 # Clementine
        58432 # SoulseekQT
        10080
        3901 # Garage
        8000 # simple-http-server
      ];
      allowedUDPPorts = [];
    };
  };
  # use FDN's DNS. Override Internet provider's DNS
  # environment.etc."resolv.conf".text = ''
  #   nameserver 84.200.69.80
  #   nameserver 2001:1608:10:25::1c04:b12f
  #   nameserver 84.200.70.40
  #   nameserver 2001:1608:10:25::9249:d69b
  #   #nameserver 80.67.169.12
  #   #nameserver 80.67.169.40
  # '';
  # disable wait online
  systemd.services.NetworkManager-wait-online.enable = false;

  fileSystems."/mnt/sdc1" = {
    device = "/dev/sdc1";
    fsType = "auto";
    options = [ "defaults" "user" "rw" "utf8" "noauto" "umask=000" ];
  };

  nix = {
    settings = {
      allowed-users = [ "@wheel" ];

      # Only allow root and sudo users
      auto-optimise-store = true;
    };
    extraOptions = ''experimental-features = nix-command flakes'';

    # FIXME update to daemonIOSchedClass daemonIOSchedPriority
    # daemonIONiceLevel = 7;
    # FIXME update to daemonCPUSchedPolicy
    # daemonNiceLevel =   10;
  };


  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "fr";
  };

  # Set your time zone.
  time.timeZone = "Europe/Paris";

  powerManagement = {
    enable = true;
    cpuFreqGovernor = "ondemand";
    powertop.enable = true;
  };

  # systemd.automount = [
  #   {
  #     enable = true;
  #     automountConfig = {
  #       Where = "/mnt/sdc1";
  #     };
  #   }
  # ];

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.ao = {
    isNormalUser = true;
    shell = pkgs.fish;
    # "wheel" enables ‘sudo’ for the user.
    extraGroups = [
      "wheel"
      "networkmanager"
      "network"
      "video"
      # "wireshark"
      "docker"
      "adbusers"
      "media"
    ];
  };

  programs.fish.enable = true;
  programs.xonsh.enable = true;
  environment.pathsToLink = [
    "/share/fish"
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.03"; # Did you read the comment?

  # system.autoUpgrade.enable = true;
  # system.autoUpgrade.allowReboot = false;

  security.apparmor = {
    enable = true;
  };

  security.sudo.extraConfig = ''Defaults insults'';

  ### Services and packages


  services.locate = {
    locate = pkgs.mlocate;
    localuser = null; # accepts mlocate running as root
    enable = true;
    interval = "hourly";
    prunePaths = [ "/tmp" "/var/tmp" "/var/cache" "/var/lock" "/var/run" "/var/spool" "/mnt" ];
  };

  services.atd.enable = true;

  # Enable bluetooth
  services.blueman.enable = true;
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = false;

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio = {
    enable = true;
    package = pkgs.pulseaudioFull; # In order to get Bluetooth support
  };

  services.tlp.enable = true;

  programs.kdeconnect.enable = true;

  environment = {
    variables = rec {
      LANG = "en_US.UTF-8";
      LC_ALL = LANG;
    };
  };

  # Programs
  programs = {
    # system
    iftop.enable = true;
    bandwhich.enable = true;
    # dev
    npm.enable = true;
    # other
    # wireshark.enable = true;
    # adb.enable = true;

    gnupg.agent = {
      enable = true;
    };

  };

  # I should try it sometimes!
  # services.magnetico.enable = true;
  # Port to be used for indexing DHT nodes. This port should be added to networking.firewall.allowedTCPPorts.
  # services.magnetico.crawler.port

  # Virtualisation
  virtualisation.libvirtd.enable = true;
  virtualisation.libvirtd.onBoot = "ignore";
  systemd.services.libvirtd.wantedBy = lib.mkForce [];
  systemd.services.libvirt-guests.wantedBy = lib.mkForce [];

  virtualisation.docker.enable = true;
  virtualisation.docker.enableOnBoot = false;
  systemd.services.docker.wantedBy = lib.mkForce [];

  # virtualisation.lxd.enable = true;
  # systemd.services.lxd.wantedBy = lib.mkForce [];

  ppom = {
    isDesktop = true;
    isLight = false;
    ssh.hardened = false;
  };

}

