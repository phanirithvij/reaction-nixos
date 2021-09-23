{ config, pkgs, ... }:

let
  sshPort = 22;
in
{
  environment.systemPackages = with pkgs; [
    ## shell environnement
    moreutils
    tmux
    fzf # fuzzy finder

    ## processus
    htop # process viewer
    # pstree
    lsof # list open files
    cpulimit # limit process CPU usage

    ## network
    mtr # interactive trace route
    iftop # connection viewer
    nmap # local network prober
    librespeed-cli # Speedtest

    ## protocols
    curl # HTTP client

    ## developpement
    git
    python3
    shellcheck # bash linter

    ## files
    file # file types
    fd # find like
    ripgrep # grep like
    exa # ls like
    du-dust # du like
    pydf # df like

    ## security
    srm # secure rm
    gnupg # reference OpenPGP implementation
    pass
  ];

  imports = [
    ../common/all.nix

    ./hardware-configuration.nix
  ];

  ppom = {
    isDesktop = false;
    isLight = true;
  };

  networking.hostName = "akesi"; # Define your hostname.
  networking.firewall.allowPing = true;

  # Set your time zone.
  time.timeZone = "Europe/Paris";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users = {
    root = {
      openssh.authorizedKeys.keys = [
        "#"
        "# WARNING: Automatically generated file"
        "# This file will be erased at every boot"
        "# This file was generated with '/usr/sbin/scw-fetch-ssh-keys'"
        "#"
        "# To add a new key, you can:"
        "#   -- Add keys on your Scaleway account https://cloud.scaleway.com/#/credentials"
        "#   -- Add keys using server tags - https://cloud.scaleway.com/#/servers/b6531225-009c-48bf-96bf-61d2b5736832"
        "ssh-rsa_XXXXXXXXXXX AUTHORIZED_KEY=ssh-rsa_YYYYYYYYYYYYYYY""
        "#        - Be sure to replace all spaces with underscores"
        "#        - $> sed 's/ /_/g' ~/.ssh/id_rsa.pub"
        "#   -- Add the keys to '/root/.ssh/instance_keys' which will be imported"
        "#"
        "# And recreate your 'authorized_keys' file with the new keys:"
        "ssh-keys --upgrade'"
        "#"
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDCl1yCz1qhl+KDKJCP84GtRDZxiLIEAr5VbVXjlD/H7Gejy8eTYY2UG0N8LMrRUPS5+gE8UI3Ic3D6XGbnpfcknoEz5HdqoU2iNHEz8Jw1MOn1f5TaiR3pKrHd7mhxBfOgYqIBlqRVugp4+OMKb80mvLw6BN/H9QmX2BAT1uQj7btr2ub6LWDTzfIYq+eJod/0no3D6Dq9ygjMpMGc3L8iG9skiaCaLhUV+lfH6QKHqUQsJvHl4tjQtQ0NLNkn4aDgnIaJrIS2oIBkRcZ4ehKwFKzlguXqwoKggvjLbuaVCRQwyHmGInMPE4OXAJ/ZifWY10o/y6bZQQQYeMW9/+3t ao@sona"
        "# Below your custom ssh keys from '/root/.ssh/instance_keys'"
      ];
    };
    ppom = {
      isNormalUser = true;
      extraGroups = [ "wheel" "users" ]; # Enable ‘sudo’ for the user.
      openssh.authorizedKeys.keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCjntXVcoGlrBwCkTWlsJk2uwCGjqToEX833hJQM9N85BazQ84sBGtMaRN8j9fSesEVcNz/YjIEbWcqq08aWnw4Qvg6Ns6fux7wvhNZWpOTB/6ApI0vI21R55lt7ZtH2neAOLkjmSuayhSPN9aJ4nvqkPQ133JHQr9Jvu6z8WqAahTVlphHtnsWtSe3cBw4U0vgXoKP/uRCTlA7p+pBbq0xOa0482Iii6aCsXFA2Ai9UzdkKQPtCe1upMZ/IMRC+esaVXsamjbIRffFoXgGXM7rP9aj+7IhHqrLwjmeLqXeQZsrvXE8Av+Zco0Wbtjy6Cg8oMuvMmIHuIr8v+LfOdBiwg6JsFSXq9PmL4OisaHjqiMKDktxRIjZI28kkuF9lBm7AYsNm5p78H1ccH5IXPcKKUaWDpaLswKNiYsOblTi0KWrMflPbg3IVPjyn0ms+ooDzbdJLl9UE6cf7zu3BqcyD/VIUvpTByNK3J+4So2xgStoxRwiVsvhzlCGc9fB+qE= ao@sona" ];
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
    port = ${builtins.toString sshPort}
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

