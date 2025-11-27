{ ... }:

{
  imports = [
    # For cloud vms. See https://nixos.org/manual/nixos/stable/index.html#sec-profile-headless
    <nixpkgs/nixos/modules/profiles/headless.nix>

    ../common

    ./hardware-configuration.nix
    ./musi-websites.nix
    ./torrent.nix
    ./webserver.nix
  ];

  ppom = {
    enable = true;
    git.email = "akesi@ppom.me";
    helix.enableNixd = false;
    ssh = {
      enable = true;
      port = 22;
      hardened = true;
    };
    reaction.enable = true;
    monit = {
      fromMail = "akesi@ppom.me";
    };
    musi-cache.enable = true;
    remote-build.allow-musi = true;
  };

  system.stateVersion = "22.05";

  # Given that akesi is headless, emergency mode is useless.
  # It's better for the system to attempt to continue booting
  # so that we can hopefully still access it remotely.
  systemd.enableEmergencyMode = false;

  networking = {
    hostName = "akesi"; # Define your hostname.
    firewall = {
      allowPing = true;
      enable = true;
    };
    defaultGateway6 = {
      address = "2001:41d0:701:1100::1";
    };
    interfaces.ens3.ipv6.addresses = [
      {
        address = "2001:41d0:701:1100::194";
        prefixLength = 64;
      }
    ];
  };

  time.timeZone = "Europe/Paris";
  i18n.defaultLocale = "en_US.UTF-8";

  boot.tmp.cleanOnBoot = true;

  swapDevices = [
    {
      device = "/swapfile";
      size = 2 * 1024; # MiB
      randomEncryption = {
        enable = true;
        # default cipher is the fastest here
      };
    }
  ];

  # Only allow paths from /nix/store to be executables
  # fileSystems."/".options = [ "noexec" ];
}
