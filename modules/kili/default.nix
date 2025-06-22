{ lib, pkgs, ... }:

{
  imports = [
    ../common
    ./hardware-configuration.nix
  ];

  ppom = {
    enable = true;
    git.email = "kili@ppom.me";
    helix.enableNixd = false;
    ssh = {
      enable = true;
      port = 22;
      hardened = true;
    };
    monit = {
      fromMail = "kili@ppom.me";
    };
    musi-cache.enable = true;
    user.musi = true;
    user.marvin = true;
  };

  # Delete more aggressively (all non-used)
  nix.gc.options = lib.mkForce "-d";

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
  };

  environment.systemPackages = [
    pkgs.wakelan
    (pkgs.writeShellScriptBin "wakepoki" ''
      exec ${pkgs.wakelan}/bin/wakelan A0:B3:CC:E9:4C:9C
    '')
  ];

  # Download more RAM
  zramSwap.enable = true;

  swapDevices = [ {
    device = "/swapfile";
    size = 2048; # 2 GiB
  } ];

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  system.stateVersion = "24.11";
}

