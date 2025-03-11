{ pkgs, ... }:
{
  imports = [
    # <nixos-hardware/dell/precision/5530>
    ../common

    ./direnv.nix
    ./down-detector.nix
    ./graphical.nix
    ./hardware.nix
    ./packages.nix
    ./peertube.nix
    ./syncthing.nix
    ./torrent.nix
    ./virt.nix
    ./vpnc.nix
  ];

  ppom = {
    enable = true;
    git.email = "sona@ppom.me";
    nvim.enableGo = true;
    nvim.steroids = true;
    packages.more = true;
    packages.xdg = true;
    tmux.desktop = true;
    user.fish = true;
  };

  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        editor = false;
        configurationLimit = 30;
        consoleMode = "auto";
        memtest86.enable = true;
      };
      efi.canTouchEfiVariables = true;
      timeout = 0;
    };
    tmp.useTmpfs = true;
    supportedFilesystems = [ "ntfs" ];
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
        8001 # simple-http-server
      ];
    };

    extraHosts = ''
      10.0.255.124	awx.poleinfo.coopaname.coop
      10.0.255.141	logs.poleinfo.coopaname.coop
      #80.67.182.69 pica03.picasoft.net pass.picasoft.net
      #80.67.182.68 caribou.picasoft.net ns01.picasoft.net
      #91.224.148.85 bob.picasoft.net ns02.picasoft.net
      #91.224.148.61 monitoring.picasoft.net
    '';
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
      # Allow sudo users
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
  users.users.ppom.extraGroups = [
    "networkmanager"
    "network"
    "video"
    "docker"
    "adbusers"
    "media"
  ];

  # I want autologin only on tty1.
  # services.getty.autologinUser = "ao";
  # From /nix/var/nix/profiles/per-user/root/nixos/nixos/modules/services/ttys/getty.nix
  # From /etc/systemd/system/getty@.service
  systemd.services."getty@tty1" = {
    serviceConfig.ExecStart = [ "" "@${pkgs.util-linux}/sbin/agetty agetty '--login-program' '${pkgs.shadow}/bin/login' '--autologin' 'ao' %I --keep-baud $TERM" ];
    overrideStrategy = "asDropin";
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.03"; # Did you read the comment?

  system.autoUpgrade.dates = "13:30";

  security.apparmor.enable = true;

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

  # FIXME logind quickfix doesn't build
  # swapDevices = [{
  #   device = "/home/hdd/swap";
  #   encrypted = {
  #     enable = true;
  #     label = "swap";
  #     keyFile = "/var/.swapkey";
  #   };
  # }];
  # # Make swap visible to logind, to be able to hibernate
  # systemd.services.systemd-logind.serviceConfig.ProtectHome = "read-only";
  # # Power button
  # services.logind = {
  #   powerKey = "suspend";
  #   powerKeyLongPress = "poweroff";
  # };
}
