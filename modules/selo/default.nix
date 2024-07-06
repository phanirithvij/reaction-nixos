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

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users = {
    ppom = {
      isNormalUser = true;
      extraGroups = [ "wheel" "users" ]; # Enable ‘sudo’ for the user.
      openssh.authorizedKeys.keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCjntXVcoGlrBwCkTWlsJk2uwCGjqToEX833hJQM9N85BazQ84sBGtMaRN8j9fSesEVcNz/YjIEbWcqq08aWnw4Qvg6Ns6fux7wvhNZWpOTB/6ApI0vI21R55lt7ZtH2neAOLkjmSuayhSPN9aJ4nvqkPQ133JHQr9Jvu6z8WqAahTVlphHtnsWtSe3cBw4U0vgXoKP/uRCTlA7p+pBbq0xOa0482Iii6aCsXFA2Ai9UzdkKQPtCe1upMZ/IMRC+esaVXsamjbIRffFoXgGXM7rP9aj+7IhHqrLwjmeLqXeQZsrvXE8Av+Zco0Wbtjy6Cg8oMuvMmIHuIr8v+LfOdBiwg6JsFSXq9PmL4OisaHjqiMKDktxRIjZI28kkuF9lBm7AYsNm5p78H1ccH5IXPcKKUaWDpaLswKNiYsOblTi0KWrMflPbg3IVPjyn0ms+ooDzbdJLl9UE6cf7zu3BqcyD/VIUvpTByNK3J+4So2xgStoxRwiVsvhzlCGc9fB+qE= ao@sona" ];
    };
  };

  # Hardware configuration
  boot.loader.grub.device = "/dev/sda";
  boot.initrd.kernelModules = [ "nvme" ];
  fileSystems."/" = { device = "/dev/sda1"; fsType = "ext4"; };
}
