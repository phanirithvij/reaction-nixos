{ config, lib, pkgs, ... }:

{
  imports = [
    ../common
    ./hardware-configuration.nix
  ];

  ppom = {
    enable = true;
    git.email = "kili@ppom.me";
    nvim.enableNixd = false;
    ssh = {
      enable = true;
      port = 22;
      # hardened = true;
    };
    # reaction.enable = true;
    monit = {
      enable = true;
      fromMail = "akesi@ppom.me";
    };
    musi-cache.enable = true;
  };

  # Use the extlinux boot loader. (NixOS wants to enable GRUB by default)
  boot.loader.grub.enable = false;
  # Enables the generation of /boot/extlinux/extlinux.conf
  boot.loader.generic-extlinux-compatible.enable = true;

  networking = {
    hostName = "kili";
    firewall = {
      allowPing = true;
      enable = true;
    };
    useDHCP = false;
    interfaces.enu1u1 = {
      useDHCP = true;
    };
  };

  time.timeZone = "Europe/Paris";

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "fr";
    useXkbConfig = true; # use xkb.options in tty.
  };

  # Enable sound.
  # services.pipewire = {
  #   enable = true;
  #   pulse.enable = true;
  # };

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  system.stateVersion = "24.11";
}

