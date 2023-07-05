{ config, pkgs, ... }:

{
  imports = [
    # For cloud vms. See https://nixos.org/manual/nixos/stable/index.html#sec-profile-headless
    <nixpkgs/nixos/modules/profiles/headless.nix>

    ../common

    ./hardware-configuration.nix
    ./pompeani.art.nix
    ./torrent.nix
    ./webserver.nix
    ./wireguard.nix
  ];

  ppom = {
    enable = true;
    git.email = "akesi@ppom.me";
    nvim.enableNixd = false;
    ssh = {
      enable = true;
      port = 22;
      hardened = true;
    };
    reaction.enable = true;
    monit = {
      enable = true;
      fromMail = "akesi@ppom.me";
    };
  };

  system.stateVersion = "22.05";

  system.autoUpgrade.enable = true;
  system.autoUpgrade.allowReboot = false;

  # Given that akesi is headless, emergency mode is useless.
  # It's better for the system to attempt to continue booting
  # so that we can hopefully still access it remotely.
  systemd.enableEmergencyMode = false;

  networking.hostName = "akesi"; # Define your hostname.
  networking.firewall.allowPing = true;
  networking.firewall.enable = true;

  time.timeZone = "Europe/Paris";
  i18n.defaultLocale = "en_US.UTF-8";

  boot.cleanTmpDir = true;

  nix = {
    settings.allowed-users = [ "root" ];
    gc = {
      automatic = true;
      options = "--delete-older-than 15d";
    };
  };

  # Only allow paths from /nix/store to be executables
  # fileSystems."/".options = [ "noexec" ];

  # prevent some potentials CVECs
  security.sudo.execWheelOnly = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users = {
    ppom = {
      isNormalUser = true;
      extraGroups = [ "wheel" "users" ]; # Enable ‘sudo’ for the user.
      openssh.authorizedKeys.keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCjntXVcoGlrBwCkTWlsJk2uwCGjqToEX833hJQM9N85BazQ84sBGtMaRN8j9fSesEVcNz/YjIEbWcqq08aWnw4Qvg6Ns6fux7wvhNZWpOTB/6ApI0vI21R55lt7ZtH2neAOLkjmSuayhSPN9aJ4nvqkPQ133JHQr9Jvu6z8WqAahTVlphHtnsWtSe3cBw4U0vgXoKP/uRCTlA7p+pBbq0xOa0482Iii6aCsXFA2Ai9UzdkKQPtCe1upMZ/IMRC+esaVXsamjbIRffFoXgGXM7rP9aj+7IhHqrLwjmeLqXeQZsrvXE8Av+Zco0Wbtjy6Cg8oMuvMmIHuIr8v+LfOdBiwg6JsFSXq9PmL4OisaHjqiMKDktxRIjZI28kkuF9lBm7AYsNm5p78H1ccH5IXPcKKUaWDpaLswKNiYsOblTi0KWrMflPbg3IVPjyn0ms+ooDzbdJLl9UE6cf7zu3BqcyD/VIUvpTByNK3J+4So2xgStoxRwiVsvhzlCGc9fB+qE= ao@sona" ];
    };
  };

  services.locate = {
    enable = true;
    interval = "daily";
    prunePaths = [ "/tmp" "/var/tmp" "/var/cache" "/var/lock" "/var/run" "/var/spool" "/var/lib/docker" ];
  };
}
