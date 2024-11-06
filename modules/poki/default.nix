{ config, pkgs, ... }:

{
  imports = [
    # For cloud vms. See https://nixos.org/manual/nixos/stable/index.html#sec-profile-headless
    # <nixpkgs/nixos/modules/profiles/headless.nix>

    ../common

    ./hardware-configuration.nix
    ./poweroff.nix
  ];

  # Cherry-picked from the headless profile
  boot.loader.grub.splashImage = null;

  ppom = {
    enable = true;
    git.email = "poki@ppom.me";
    nvim.enableNixd = false;
    ssh = {
      enable = true;
      port = 22;
      hardened = true;
    };
    reaction = {
      enable = true;
      enableNginx = false;
    };
    monit = {
      enable = true;
      fromMail = "poki@ppom.me";
    };
  };

  services.openssh.allowSFTP = true;

  system.stateVersion = "23.11";

  networking.hostName = "poki";
  networking.firewall.allowPing = true;
  networking.firewall.enable = true;

  time.timeZone = "Europe/Paris";
  i18n.defaultLocale = "en_US.UTF-8";

  boot.loader.grub = {
    enable = true;
    device = "/dev/disk/by-id/ata-ST1000LM024_HN-M101MBB_S31LJ9AG907492";
  };
  boot.kernelParams = [ "panic=1" "boot.panic_on_fail" ];
  boot.tmp.cleanOnBoot = true;

  fileSystems."/backup" = {
    device = "/dev/mapper/vg_backup-lv_backup";
    fsType = "ext4";
  };

  nix = {
    settings.allowed-users = [ "root" ];
    gc = {
      automatic = true;
      options = "--delete-older-than 15d";
    };
  };

  # prevent some potentials CVECs
  security.sudo.execWheelOnly = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users = {
    ppom = {
      isNormalUser = true;
      extraGroups = [ "wheel" "users" ];
      openssh.authorizedKeys.keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCjntXVcoGlrBwCkTWlsJk2uwCGjqToEX833hJQM9N85BazQ84sBGtMaRN8j9fSesEVcNz/YjIEbWcqq08aWnw4Qvg6Ns6fux7wvhNZWpOTB/6ApI0vI21R55lt7ZtH2neAOLkjmSuayhSPN9aJ4nvqkPQ133JHQr9Jvu6z8WqAahTVlphHtnsWtSe3cBw4U0vgXoKP/uRCTlA7p+pBbq0xOa0482Iii6aCsXFA2Ai9UzdkKQPtCe1upMZ/IMRC+esaVXsamjbIRffFoXgGXM7rP9aj+7IhHqrLwjmeLqXeQZsrvXE8Av+Zco0Wbtjy6Cg8oMuvMmIHuIr8v+LfOdBiwg6JsFSXq9PmL4OisaHjqiMKDktxRIjZI28kkuF9lBm7AYsNm5p78H1ccH5IXPcKKUaWDpaLswKNiYsOblTi0KWrMflPbg3IVPjyn0ms+ooDzbdJLl9UE6cf7zu3BqcyD/VIUvpTByNK3J+4So2xgStoxRwiVsvhzlCGc9fB+qE= ao@sona" ];
    };
    musi = {
      isNormalUser = true;
      extraGroups = [ "users" ];
      openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMejg0vhFiS9vjVYX8IiXgq4kRy8c+XXbkaaio6i4BXP root@musi" ];
    };
    bertille = {
      isNormalUser = true;
      extraGroups = [ "users" ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBrSvK7feOr37nP0hdOylZG1GzYBssHtVrWGs3/0zFha bertille@ordi"
      ];
    };
  };

  systemd.tmpfiles.rules = [
    "d /backup/musi     0700 musi     root - -"
    "d /backup/ppom     0700 ppom     root - -"
    "d /backup/bertille 0700 bertille root - -"
  ];
}
