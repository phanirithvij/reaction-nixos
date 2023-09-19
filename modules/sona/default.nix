{ lib, config, pkgs, ... }:
{
  imports = [
    # <nixos-hardware/dell/precision/5530>
    ../common

    ./direnv.nix
    ./down-detector.nix
    ./graphical.nix
    ./hardware-configuration.nix
    ./packages.nix
    ./peertube.nix
    ./virt.nix
    ./vpnc.nix
  ];

  ppom = {
    enable = true;
    tmux.desktop = true;
    packages.more = true;
    git.email = "sona@ppom.me";
    nvim.steroids = true;
  };

  boot = {
    loader = {
      systemd-boot.enable = true;
      systemd-boot.editor = false;
      efi.canTouchEfiVariables = true;
      timeout = 1;
    };
    tmp.useTmpfs = true;
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
        # 58432 # SoulseekQT
        8000 # simple-http-server
      ];
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

  # I want autologin only on tty1.
  # services.getty.autologinUser = "ao";
  # From /nix/var/nix/profiles/per-user/root/nixos/nixos/modules/services/ttys/getty.nix
  # From /etc/systemd/system/getty@.service
  systemd.services."getty@tty1" = {
    serviceConfig.ExecStart = [ "" "@${pkgs.util-linux}/sbin/agetty agetty '--login-program' '${pkgs.shadow}/bin/login' '--autologin' 'ao' %I --keep-baud $TERM" ];
    overrideStrategy = "asDropin";
  };

  programs.fish.enable = true;
  environment.pathsToLink = [ "/share/fish" ];

  security.doas = {
    enable = true;
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.03"; # Did you read the comment?

  system.autoUpgrade.dates = "10:00";
  systemd.services.nixos-upgrade.serviceConfig = {
    # Seems unused for now https://www.kernel.org/doc/html/v6.1/block/ioprio.html
    # CFQ is the only IO Scheduler concerned but it's only for reads and it
    # is somewhat deprecated
    IOSchedulingClass = "idle";
  };

  security.apparmor.enable = true;

  services.locate = {
    enable = true;
    locate = pkgs.mlocate;
    localuser = null; # accepts mlocate running as root
    interval = "hourly";
    prunePaths = [ "/tmp" "/var/tmp" "/var/cache" "/var/lock" "/var/run" "/var/spool" "/mnt" ];
  };

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
    # kdeconnect.enable = true;
    npm.enable = true;
    bandwhich.enable = true;
  };
}

