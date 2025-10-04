{ lib, pkgs, ... }:
{
  imports = [
    <nixos-hardware/framework/13-inch/7040-amd>
    ../common

    ./hardware-configuration.nix
    ./android.nix
    ../sona/direnv.nix
    ../sona/down-detector.nix
    ../sona/graphical.nix
    ../sona/packages.nix
    ../sona/syncthing.nix
    # ../sona/torrent.nix # No wireguard setup right now
    ../sona/virt.nix
  ];

  ppom = {
    enable = true;
    git.email = "lipu@ppom.me";
    nvim.enableGo = true;
    nvim.steroids = true;
    packages.more = true;
    packages.xdg = true;
    tmux.desktop = true;
    user.fish = true;
  };

  boot = {
    initrd.luks.devices = {
      "luks-2863a70c-d9a9-4d4b-a071-8fa60531b477" = {
        device = "/dev/disk/by-uuid/2863a70c-d9a9-4d4b-a071-8fa60531b477";
      };
    };
    loader = {
      systemd-boot = {
        enable = true;
        editor = true;
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
    hostName = "lipu";
    useDHCP = false;
    networkmanager = {
      enable = true;
      wifi = {
        powersave = true;
        macAddress = "stable-ssid";
      };
    };

    firewall = {
      enable = true;
      allowedTCPPorts = [
        # 58432 # SoulseekQT
        8001 # simple-http-server
      ];
    };

    extraHosts = ''
      #80.67.182.69 pica03.picasoft.net pass.picasoft.net
      #80.67.182.68 caribou.picasoft.net ns01.picasoft.net
      #91.224.148.85 bob.picasoft.net ns02.picasoft.net
      #91.224.148.61 monitoring.picasoft.net
    '';
  };

  # disable wait online
  systemd.services.NetworkManager-wait-online.enable = false;

  fileSystems."/mnt/sdc1" = {
    device = "/dev/sdc1";
    fsType = "auto";
    options = [ "defaults" "user" "rw" "utf8" "noauto" "umask=000" ];
  };

  nix.settings.trusted-users = ["ppom"];

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

  users.users.ppom.extraGroups = [
    "networkmanager"
    "network"
    "video"
    "docker"
    "adbusers"
    "media"
  ];

  # I want autologin only on tty1.
  # services.getty.autologinUser = "ppom";
  # From /nix/var/nix/profiles/per-user/root/nixos/nixos/modules/services/ttys/getty.nix
  # From /etc/systemd/system/getty@.service
  systemd.services."getty@tty1" = {
    serviceConfig.ExecStart = [ "" "@${pkgs.util-linux}/sbin/agetty agetty '--login-program' '${pkgs.shadow}/bin/login' '--autologin' 'ppom' %I --keep-baud $TERM" ];
    overrideStrategy = "asDropin";
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?

  system.autoUpgrade.dates = "13:30";

  security.apparmor.enable = true;
  security.polkit.enable = true;

  environment = {
    variables = rec {
      LANG = "en_US.UTF-8";
      LC_ALL = LANG;
      EDITOR = lib.mkForce "hx";
      VISUAL = lib.mkForce "hx";
    };
  };

  # Programs
  programs = {
    git.config.core.editor = "hx";
    gnupg.agent.enable = true;
    # kdeconnect.enable = true;
    npm.enable = true;
    bandwhich.enable = true;
  };

  services.fwupd.enable = true;

  # FIXME logind quickfix doesn't build
  # # Make swap visible to logind, to be able to hibernate
  # systemd.services.systemd-logind.serviceConfig.ProtectHome = "read-only";
  # # Power button
  # services.logind = {
  #   powerKey = "suspend";
  #   powerKeyLongPress = "poweroff";
  # };
}
