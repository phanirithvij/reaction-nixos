{ config, pkgs, ... }:

let
  sshPort = 22;
in
{
  imports = [
    ../common/all.nix

    ./hardware-configuration.nix
    # ./openvpn.nix
    ./pompeani.art.nix
    # ./turn.nix
    ./torrent.nix
    ./webserver.nix
    ./wireguard.nix
  ];

  ppom = {
    isDesktop = false;
    isLight = true;
  };

  system.stateVersion = "22.05";

  system.autoUpgrade.enable = true;
  system.autoUpgrade.allowReboot = false;

  networking.hostName = "akesi"; # Define your hostname.
  networking.firewall.allowPing = true;
  networking.firewall.enable = true;

  time.timeZone = "Europe/Paris";
  i18n.defaultLocale = "en_US.UTF-8";

  boot.cleanTmpDir = true;

  # Only allow root to use nix
  nix.settings.allowed-users = [ "root" ];

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

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    passwordAuthentication = false;
    allowSFTP = false;
    # challengeResponseAuthentication = false;
    extraConfig = ''
    '';
  };

  # Fail2ban service
  services.fail2ban.enable = true;
  # Stick with default banaction, banaction-allports, bantime
  services.fail2ban.jails.sshd = ''
    port = ${builtins.toString sshPort}
    enabled = true
    banaction = iptables-multiport
    maxretry = 5
    findtime = 1200
    bantime = 4800
  '';

  services.locate = {
    enable = true;
    interval = "daily";
    prunePaths = [ "/tmp" "/var/tmp" "/var/cache" "/var/lock" "/var/run" "/var/spool" "/var/lib/docker" ];
  };
}
