{ config, pkgs, ... }:
{
  imports = [
    ../common

    ./anpa.nix # container
    ./backup.nix
    ./converter
    ./dolibarr.nix
    ./hardware-configuration.nix
    ./languagetool.nix
    ./listmonk.nix
    ./mail.nix
    ./monitoring.nix
    ./postgresql.nix
    ./rssify/default.nix
    ./streama.nix
    ./slskd.nix
    ./tor.nix
    ./users.nix
    ./vaultwarden.nix

    ./websites.nix
    ./babos.land.nix
    ./music.ppom.me.nix
    ./edit.ppom.me
    ./file.ppom.me.nix
  ];

  ppom = {
    enable = true;
    packages.more = true;
    git.email = "musi@ppom.me";
    ssh = {
      enable = true;
      port = [ 22 123 ];
      hardened = false;
    };
    reaction.enable = true;
    monit = {
      enable = true;
      fromMail = "musi@ppom.me";
    };
  };

  environment.systemPackages = [ (pkgs.callPackage ../../pkgs/crowdsec {}) ];

  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        editor = false;
      };
      efi.canTouchEfiVariables = true;
    };
    tmp.useTmpfs = true;
  };

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

  security.doas = {
    enable = true;
  };

  nix = {
    settings.allowed-users = [ "root" ];
    gc = {
      automatic = true;
      dates = "04:00";
      options = "--delete-older-than 15d";
      persistent = false;
    };
  };

  virtualisation.docker.enable = true;
  boot.kernel.sysctl."net.ipv4.ip_forward" = true;

  # I needed that after installing slskd, but I don't see why.
  boot.kernel.sysctl."fs.inotify.max_user_watches" = 10 * 512 * 1024;
  boot.kernel.sysctl."fs.inotify.max_user_instances" = 512;

  # SMART daemon → disk health check
  services.smartd.enable = true;

  # Secondary services
  programs.iftop.enable = true;

  services.locate = {
    locate = pkgs.mlocate;
    localuser = null; # accepts mlocate running as root
    enable = true;
    interval = "daily";
    prunePaths = [ "/tmp" "/var/tmp" "/var/cache" "/var/lock" "/var/run" "/var/spool" "/var/lib/docker" ];
  };

  services.journald.extraConfig = ''
    SystemMaxUse=6G
    MaxRetentionSec=1month
  '';

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

