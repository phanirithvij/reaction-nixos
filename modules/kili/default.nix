{ pkgs, ... }:

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
      hardened = true;
    };
    reaction = {
      enable = true;
      enableNginx = false;
      enableGPTBot = false;
    };
    monit = {
      enable = true;
      fromMail = "kili@ppom.me";
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
  };

  environment.systemPackages = [
    pkgs.wakelan
    (pkgs.writeShellScriptBin "wakepoki" ''
      exec ${pkgs.wakelan}/bin/wakelan A0:B3:CC:E9:4C:9C
    '')
  ];

  users.users.musi = {
    isNormalUser = true;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMejg0vhFiS9vjVYX8IiXgq4kRy8c+XXbkaaio6i4BXP root@musi"
    ];
  };

  swapDevices = [ {
    device = "/swapfile";
  } ];

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

