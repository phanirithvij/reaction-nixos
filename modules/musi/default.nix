{ config, pkgs, ... }:

let
  sshPort = 22;
in
{
  imports = [
    ../common/all.nix

    ./anpa.nix # container
    ./backup.nix
    ./clement.nix
    ./funkwhale/default.nix
    ./hardware-configuration.nix
    ./languagetool.nix
    ./mail.nix
    ./monitoring.nix
    ./nextcloud/default.nix
    ./rzw.nix
    ./streama.nix
    ./tor.nix
    ./vaultwarden.nix
    ./websites.nix
  ];

  ppom = {
    isDesktop = false;
    isLight = false;
  };

  services.rzw = {
    enable = true;
    domain = "ruleze.world";
    adminPasswordFile = "/var/secrets/rzw-admin.secret";
  };

  services.funkwhale = {
    enable = true;
    funkwhaleVersion = "1.1.4";
    domainName = "music.ppom.me";
    envFile = "/root/secrets/funkwhale.secrets";
    musicDir = "/data/funkwhale/music";
    dataDir = "/data/funkwhale/data";
    importCronEnable = true;
    importCronLibraryID = "307d7f12-23df-49c1-9394-e39daf94047c";
  };

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.editor = false;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.tmpOnTmpfs = true;

  fileSystems."/data" = {
    device = "/dev/mapper/vg_data-lv_data";
    fsType = "ext4";
  };

  networking.hostName = "musi"; # Define your hostname.
  networking.useDHCP = false;
  networking.interfaces.enp6s0.useDHCP = true;

  # Set your time zone.
  time.timeZone = "Europe/Paris";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "fr";
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users = {
    ppom = {
      isNormalUser = true;
      extraGroups = [ "wheel" "users" ];
      openssh.authorizedKeys.keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCjntXVcoGlrBwCkTWlsJk2uwCGjqToEX833hJQM9N85BazQ84sBGtMaRN8j9fSesEVcNz/YjIEbWcqq08aWnw4Qvg6Ns6fux7wvhNZWpOTB/6ApI0vI21R55lt7ZtH2neAOLkjmSuayhSPN9aJ4nvqkPQ133JHQr9Jvu6z8WqAahTVlphHtnsWtSe3cBw4U0vgXoKP/uRCTlA7p+pBbq0xOa0482Iii6aCsXFA2Ai9UzdkKQPtCe1upMZ/IMRC+esaVXsamjbIRffFoXgGXM7rP9aj+7IhHqrLwjmeLqXeQZsrvXE8Av+Zco0Wbtjy6Cg8oMuvMmIHuIr8v+LfOdBiwg6JsFSXq9PmL4OisaHjqiMKDktxRIjZI28kkuF9lBm7AYsNm5p78H1ccH5IXPcKKUaWDpaLswKNiYsOblTi0KWrMflPbg3IVPjyn0ms+ooDzbdJLl9UE6cf7zu3BqcyD/VIUvpTByNK3J+4So2xgStoxRwiVsvhzlCGc9fB+qE= ao@sona" ];
    };
    uploader = {
      isNormalUser = true;
      home = "/home/uploader";
      group = "nginx";
      openssh.authorizedKeys.keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC+QKvUjiZ4MnIzGaWJjVevXyEc8Ja3aORPE+gSYgBGwVOPK5SR9oQPyeBFQWjRuY9HeCarKoCWC4X7n0yg1hcYmFs4U7Tm1eb179+YYXIW2KPZOLrVBrAWzNTUPhcToo1/zsnLmFKbU/Kn/lt0YHo0pfDfRE1mFi2ORIEtyqg6nCeZkcb5DfunXG6lEejTm41aDoxs3UjqSBStP0GmX5ReVENRUxo0UzPcW1ImXLhD5A2BcOXvbaUp1lMWVfqY28gbYVDMbYyqDfMA3+yacXKoQcUwgDC9tKKzaxWuuYs/y+vVM01aARK7ol++9f5b1205LNDRVzzUIezrDZsWcggclcCaeKFy2rOBsVHj4wuMp9+M4NWF0NKetJsFOkas4BNUJXhSuGrhtvVeqQBtgtSt6gH7hRmPp/NZpG7OniK2g7Zm/jFte8aOPNWZL0iKv2fLNdPkgdx63MjgVDu5L1Z7I6kIvTBIRluLnzoOdsEWBm/9y0SacCsyRJKA2kPXfmc= ao@sona" ];
      extraGroups = [ "users" ];
    };
  };

  # Cron jobs
  services.cron = let
    uptimeCalc = (pkgs.writeScript "uptimeCalc.sh" ''uptime > ${config.users.users.ppom.home}/uptimes/$(date '+%y-%m-%d')'');
  in {
    enable = true;
    systemCronJobs = [
      ''23 0 * * *      ppom    ${uptimeCalc}''
    ];
  };

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.openssh.ports = [ sshPort ];
  services.openssh.permitRootLogin = "no";
  # Mosh extension (doesn't work: TODO)
  programs.mosh.enable = true;

  # Open ports in the firewall.
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [
    sshPort
  ];

  # Doas
  security.doas = {
    enable = true;
  };

  # Fail2ban service
  services.fail2ban.enable = true;
  # Stick with default banaction, banaction-allports, bantime
  services.fail2ban.jails.sshd = ''
    enabled = true
    port = ${builtins.toString sshPort}

    maxretry = 5
    findtime = 1200
    bantime = 2400
  '';

  # Only allow root to use nix
  nix.allowedUsers = [ "root" ];

  virtualisation.docker.enable = true;
  boot.kernel.sysctl."net.ipv4.ip_forward" = true;

  # SMART daemon → disk health check
  services.smartd.enable = true;

  # Secondary services
  programs.iftop.enable = true;

  services.locate = {
    locate = pkgs.mlocate;
    localuser = null; # accepts mlocate running as root
    enable = true;
    interval = "daily";
    prunePaths = [ "/tmp" "/var/tmp" "/var/cache" "/var/lock" "/var/run" "/var/spool" "/var/lib/docker" ];
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.09"; # Did you read the comment?

  system.autoUpgrade.enable = true;
  system.autoUpgrade.allowReboot = false;
}

