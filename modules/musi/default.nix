{ config, pkgs, ... }:
{
  imports = [
    ../common

    ./akesi.nix
    ./anpa.nix # container
    ./backup.nix
    ./converter
    ./dolibarr.nix
    ./dyndns.nix
    ./hardware-configuration.nix
    ./languagetool.nix
    # ./listmonk.nix
    ./matrix.nix
    ./monitoring.nix
    ./ntfy.nix
    ./postgresql.nix
    ./photoprism.nix
    ./rssify/default.nix
    ./streama.nix
    ./slskd.nix
    ./syncthing.nix
    ./tor.nix
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
      enable = true;
      fromMail = "musi@ppom.me";
    };
    nvim.enableNixd = true;
    nvim.enableGo = true;
    user.fish = true;
  };

  services.reaction = {
    settings.patterns.ip.ignore = [ "192.168.1.253" ];
    # loglevel = "DEBUG";
  };

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

  # Secondary services
  programs.iftop.enable = true;

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
}

