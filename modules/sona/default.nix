{ lib, config, pkgs, ... }:
{
  imports = [
    ../common

    ./direnv.nix
    ./down-detector.nix
    ./graphical.nix
    ./hardware-configuration.nix
    ./packages.nix
    ./virt.nix
    ./vpnc.nix
  ];

  ppom = {
    enable = true;
    tmux.desktop = true;
    packages.more = true;
    git.email = "paco@ecomail.io";
    nvim.steroids = true;
  };

  specialisation = {
    # A (future) wifi proxy
    # withAccessPoint = {
    #   imports = [ ./accesspoint.nix ];
    # }
  };

  # Boot
  boot = {
    loader.systemd-boot.enable = true;
    loader.systemd-boot.editor = false;
    loader.efi.canTouchEfiVariables = true;
    tmpOnTmpfs = true;
    # add ntfs support
    supportedFilesystems = [ "ntfs" ];

    # The 5.15 mainline has a "dim brightness" bug for me
    kernelPackages = pkgs.linuxKernel.packages.linux_6_1;
  };

  # Networking
  networking = {
    hostName = "sona";
    useDHCP = false;
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
      # Only allow root and sudo users
      allowed-users = [ "@wheel" ];
      experimental-features = "nix-command flakes";
    };
  };

  console = {
    font = "Lat2-Terminus16";
    keyMap = "fr";
  };

  time.timeZone = "Europe/Paris";

  powerManagement = {
    enable = true;
    cpuFreqGovernor = "ondemand";
    powertop.enable = true;
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.ao = {
    isNormalUser = true;
    shell = pkgs.fish;
    extraGroups = [
      "wheel"
      "networkmanager"
      "network"
      "video"
      "docker"
      "adbusers"
      "media"
    ];
  };

  services.getty.autologinUser = "ao";

  programs.fish.enable = true;
  environment.pathsToLink = [ "/share/fish" ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.03"; # Did you read the comment?

  security.apparmor.enable = true;

  services.locate = {
    enable = true;
    locate = pkgs.mlocate;
    localuser = null; # accepts mlocate running as root
    interval = "hourly";
    prunePaths = [ "/tmp" "/var/tmp" "/var/cache" "/var/lock" "/var/run" "/var/spool" "/mnt" ];
  };

  services.atd.enable = true;
  services.tlp.enable = true;

  environment = {
    variables = rec {
      LANG = "en_US.UTF-8";
      LC_ALL = LANG;
    };
  };

  # Programs
  programs = {
    gnupg.agent.enable = true;
    kdeconnect.enable = true;
    npm.enable = true;
    bandwhich.enable = true;
  };
}

