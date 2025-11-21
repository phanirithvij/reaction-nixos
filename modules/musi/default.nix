{ config, lib, ... }:
{
  imports = [
    ../common

    ./akesi.nix
    ./anpa.nix # container
    ./backup.nix
    ./converter
    ./compote.nix
    ./dyndns.nix
    ./hardware-configuration.nix
    ./immich.nix
    ./languagetool.nix
    ./monitoring.nix
    ./ntfy.nix
    ./postgresql.nix
    ./streama.nix
    ./signal.nix
    ./slskd.nix
    ./syncthing.nix
    ./users.nix
    ./vaultwarden.nix

    ./websites.nix
    ./babos.land.nix
    ./music.ppom.me.nix
    ./edit.ppom.me
    ./file.ppom.me.nix
    ./fesse.cloud.nix
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
      fromMail = "musi@ppom.me";
    };
    helix.enableNixd = true;
    helix.enableGo = true;
    user.fish = true;
    remote-build.hosts = [
      "akesi"
      "poki"
    ];
  };

  services.reaction = {
    settings = {
      patterns = {
        ip.ignore = [ "192.168.1.253" ];
        unit.ignore = [ "languagetool.service" ];
      };
    };
    # loglevel = "DEBUG";
  };

  systemd.services.rebuild-poki = {
    after = lib.mkForce [ "restic-backups-data2.service" ];
    wantedBy = lib.mkForce [ "restic-backups-data2.service" ];
  };

  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        editor = false;
      };
      efi.canTouchEfiVariables = true;
    };
    tmp.cleanOnBoot = true;
  };

  fileSystems."/data" = {
    device = "/dev/mapper/vg_data-lv_data";
    fsType = "ext4";
  };

  networking.hostName = "musi"; # Define your hostname.
  networking.useDHCP = false;
  networking.interfaces.enp6s0 = {
    useDHCP = true;
    # I have connectivity issues that way and I don't know why.
    # ipv4.addresses = [{
    #   address = "192.168.1.35";
    #   prefixLength = 24;
    # }];
    # ipv6.addresses = [{
    #   address = "2a01:e0a:b3a:1dd0::2";
    #   prefixLength = 64;
    # }];
  };

  # Set your time zone.
  time.timeZone = "Europe/Paris";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "fr";
  };

  # Update all channels on upgrade, not only the default one.
  systemd.services.nixos-upgrade.serviceConfig.ExecStartPre = [ "${config.nix.package}/bin/nix-channel --update" ];

  virtualisation.docker.enable = true;
  boot.kernel.sysctl."net.ipv4.ip_forward" = true;

  # SMART daemon → disk health check
  services.smartd.enable = true;

  # Firmware upgrade
  services.fwupd.enable = true;

  # Secondary services
  programs.iftop.enable = true;

  services.journald.extraConfig = ''
    SystemMaxUse=6G
    MaxRetentionSec=1month
  '';

  swapDevices = [ {
    device = "/swapfile";
    size = 22 * 1024; # MiB
    randomEncryption = {
      enable = true;
      # default cipher is the fastest here
    };
  } ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.09"; # Did you read the comment?
}

