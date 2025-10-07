{ ... }:
{
  imports = [
    # For cloud vms. See https://nixos.org/manual/nixos/stable/index.html#sec-profile-headless
    # <nixpkgs/nixos/modules/profiles/headless.nix>

    ../common

    ./hardware-configuration.nix
    ./poweroff.nix
  ];

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
    musi-cache.enable = true;
    remote-build.allow-musi = true;
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
    device = "/dev/disk/by-id/ata-ST2000DM008-2FR102_ZFL1V5Y2";
    # Cherry-picked from the headless profile
    splashImage = null;
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

  users.users = {
    musi = {
      isNormalUser = true;
      extraGroups = [ "users" ];
      openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMejg0vhFiS9vjVYX8IiXgq4kRy8c+XXbkaaio6i4BXP root@musi" ];
    };
  };

  systemd.tmpfiles.rules = [
    "d /backup/musi     0700 musi     root - -"
    "d /backup/ppom     0700 ppom     root - -"
    "d /backup/bertille 0700 bertille root - -"
  ];
}
