{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  environment.systemPackages = with pkgs; [
    tmux fzf htop curl git file fd ripgrep exa du-dust pydf srm gnupg pass
  ];
  
  networking.hostName = "akesi"; # Define your hostname.
  networking.firewall.allowPing = true;

  # Set your time zone.
  time.timeZone = "Europe/Paris";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users = {
    root = {
      openssh.authorizedKeys.keys = [ "..." ];
    };
    ppom = {
      isNormalUser = true;
      extraGroups = [ "wheel" "users" ];
      openssh.authorizedKeys.keys = [ "..." ];
    };
  };

  boot.cleanTmpDir = true;

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [ ];

  # Fail2ban service
  services.fail2ban.enable = true;
  # Stick with default banaction, banaction-allports, bantime
  services.fail2ban.jails.sshd = ''
    port = 22
    enabled = true
    banaction = iptables-multiport
    maxretry = 5
    findtime = 1200
    bantime = 2400
  '';

  # Only allow root to use nix
  nix.allowedUsers = [ "root" ];

  services.locate = {
    enable = true;
    interval = "daily";
    prunePaths = [ "/tmp" "/var/tmp" "/var/cache" "/var/lock" "/var/run" "/var/spool" "/var/lib/docker" ];
  };
}

