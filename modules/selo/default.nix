{ modulesPath, ... }:
{
  imports = [
    # For cloud vms. See https://nixos.org/manual/nixos/stable/index.html#sec-profile-headless
    (modulesPath + "/profiles/headless.nix")
    (modulesPath + "/profiles/qemu-guest.nix")

    ../common
  ];

  ppom = {
    enable = true;
    git.email = "selo@ppom.me";
    nvim.enableNixd = false;
    ssh = {
      enable = true;
      port = 22;
      hardened = true;
    };
    reaction.enable = true;
    monit = {
      enable = true;
      fromMail = "selo@ppom.me";
    };
  };

  system.stateVersion = "24.05";

  # Given that selo is headless, emergency mode is useless.
  # It's better for the system to attempt to continue booting
  # so that we can hopefully still access it remotely.
  systemd.enableEmergencyMode = false;

  networking = {
    hostName = "selo"; # Define your hostname.
    firewall = {
      allowPing = true;
      enable = true;
    };
    defaultGateway.address = "192.168.1.1";
    defaultGateway6.address = "2001:41d0:701:1100::1";
    interfaces.ens3.ipv6.addresses = [{
      address = "2001:41d0:701:1100::2";
      prefixLength = 64;
    }];
  };

  # TODO https://wiki.arn-fai.net/documentation:hosting:resal_vps

  services.udev.extraRules = ''
    net.ifnames=0
  '';

  time.timeZone = "Europe/Paris";
  i18n.defaultLocale = "en_US.UTF-8";

  boot.tmp.cleanOnBoot = true;

  # Only allow paths from /nix/store to be executables
  fileSystems."/".options = [ "noexec" ];

  # Hardware configuration
  boot.loader.grub.device = "/dev/sda";
  boot.initrd.kernelModules = [ "nvme" ];
  fileSystems."/" = { device = "/dev/sda1"; fsType = "ext4"; };
}
