{ lib, config, pkgs, ... }:
{
  imports = [
      ../common/ppom.nix
      ../common/tmux.nix

      ./direnv.nix
      ./hardware-configuration.nix
      ./mpd.nix
      ./nginx.nix
      ./packages.nix
      ./userunits.nix
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
    # plymouth = { enable = true; logo = pkgs.fetchurl { url = "https://u.ppom.me/plymouth.png"; sha256 = "b2d44f5120e6528cec6dea9b6b8ad049e57b7f65670d8f05ca1c18b5a43c63d7"; }; };
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

    firewall.enable = true;
    firewall.allowedTCPPorts = [
      5500 # Clementine
      58432 # SoulseekQT
      10080
    ];
    firewall.allowedUDPPorts = [];
  };
  # use FDN's DNS. Override Internet provider's DNS
  environment.etc."resolv.conf".text = ''
    nameserver 84.200.69.80
    nameserver 2001:1608:10:25::1c04:b12f
    nameserver 84.200.70.40 
    nameserver 2001:1608:10:25::9249:d69b
    #nameserver 80.67.169.12
    #nameserver 80.67.169.40
  '';
  # disable wait online
  systemd.services.NetworkManager-wait-online.enable = false;

  fileSystems."/mnt/sdc1" = {
    device = "/dev/sdc1";
    fsType = "auto";
    options = [ "defaults" "user" "rw" "utf8" "noauto" "umask=000" ];
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

  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;
    enableCtrlAltBackspace = true;
    layout = "fr";
    # Enable touchpad support.
    libinput.enable = true;
    # use dwm
    windowManager.dwm.enable = true;
    # configure LightDM
    displayManager = {
      lightdm.enable = true;
      # autoLogin
      autoLogin.enable = true;
      autoLogin.user = "ao";
    };
    # The dots per inch of my screen.
    dpi = 96;
  };

  # systemd.automount = [
  #   {
  #     enable = true;
  #     automountConfig = {
  #       Where = "/mnt/sdc1";
  #     };
  #   }
  # ];

  programs.xss-lock = {
    enable = true;
    lockerCommand = "/run/wrappers/bin/slock";
  };

  ### BEGIN UNFREE
  # Yeah, I'm not proud of that
  nixpkgs.config.allowUnfree = true;
  # nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ "steam" "nvidia" ];

  # Nvidia driver
  services.xserver.videoDrivers = [ "nvidia" ];

  # Steam related
  environment.systemPackages = [ pkgs.steam ];
  hardware.opengl.driSupport32Bit = true;
  hardware.opengl.extraPackages32 = with pkgs.pkgsi686Linux; [ libva ];
  hardware.pulseaudio.support32Bit = true;
  ### END UNFREE

  # Fix of: Can't shutdown after having suspended the laptop by closing it.
  # Fix found here: https://bugs.launchpad.net/ubuntu/+source/systemd/+bug/1441253
  # Sounds like one of the systemd bugs that has never been fixed...
  services.logind.lidSwitch = "suspend-then-hibernate";

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.ao = {
    isNormalUser = true;
    # "wheel" enables ‘sudo’ for the user.
    extraGroups = [
      "wheel"
      "networkmanager"
      "network"
      "video"
      "wireshark"
      "docker"
      "adbusers"
      "media"
    ];
  };
  users.users.dumb = {
    isNormalUser = true;
    extraGroups = [
      "networkmanager"
      "video"
    ];
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.03"; # Did you read the comment?

  # system.autoUpgrade.enable = true;
  # system.autoUpgrade.allowReboot = false;

  # setuid wrapper for slock
  security.wrappers.slock.source = "${pkgs.slock.out}/bin/slock";

  security.apparmor = {
    enable = true;
  };

  security.sudo.extraConfig = ''Defaults insults'';

  ### Services and packages


  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryFlavor = "gnome3";
  };

  services.locate = {
    enable = true;
    interval = "hourly";
    prunePaths = [ "/tmp" "/var/tmp" "/var/cache" "/var/lock" "/var/run" "/var/spool" "/home/hdd/debian/etc" "/mnt" ];
  };

  # Cron jobs
  services.cron = {
    enable = true;
    systemCronJobs = [
      # ''0 22,0 * * *      root    cd /etc/nixos && git add -A && git commit -m "auto commit"''
      # ''*/10 * * * *      ao      if ping framasoft.org; then down_detector.sh || mail 
    ];
    cronFiles = [
      ''${pkgs.writeText "ao.crontab" ''
        */2 * * * * ao /home/ao/bin/cron_check_battery
      ''}''
    ];
  };

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

  # Udev rules
  programs.light.enable = true;

  environment = {
    variables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
      BROWSER = "firefox";
    };
    homeBinInPath = true;
  };

  # Programs
  programs = {
    # system
    iftop.enable = true;
    autojump.enable = true;
    bandwhich.enable = true;
    # dev
    npm.enable = true;
    # other
    browserpass.enable = true;
    #steam.enable;
    wireshark.enable = true;
    adb.enable = true;
  };

  # services.ipfs = {
    # enable = true;
    # autoMount = true;
  # };

  # I should try it sometimes!
  # services.magnetico.enable = true;
  # Port to be used for indexing DHT nodes. This port should be added to networking.firewall.allowedTCPPorts.
  # services.magnetico.crawler.port

  # Flatpak
  services.flatpak.enable = true;
  xdg.portal.enable = true;

  # Virtualisation
  virtualisation.libvirtd.enable = true;
  virtualisation.libvirtd.onBoot = "ignore";
  systemd.services.libvirtd.wantedBy = lib.mkForce [];
  systemd.services.libvirt-guests.wantedBy = lib.mkForce [];

  virtualisation.docker.enable = true;
  virtualisation.docker.enableOnBoot = false;
  systemd.services.docker.wantedBy = lib.mkForce [];

  virtualisation.lxd.enable = true;
  systemd.services.lxd.wantedBy = lib.mkForce [];

  ppom = {
    isDesktop = true;
  };

}

