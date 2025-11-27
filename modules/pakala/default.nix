{
  lib,
  modulesPath,
  pkgs,
  ...
}:
{
  imports = [
    # For cloud vms. See https://nixos.org/manual/nixos/stable/index.html#sec-profile-headless
    # (modulesPath + "/profiles/headless.nix")
    (modulesPath + "/profiles/qemu-guest.nix")

    ../common
  ];

  environment.systemPackages = with pkgs; [
    moreutils
    htop
    fd
    ripgrep
    jq
    du-dust
    file
  ];

  environment.shellAliases = {
    n = "cd /etc/nixos/modules";
    ll = "ls -lh";
    la = "ls -a";
  };

  programs.bash.interactiveShellInit = ''
    [ -f ${pkgs.fzf}/share/fzf/key-bindings.bash ] && source ${pkgs.fzf}/share/fzf/key-bindings.bash
    function nix-dir()  { echo "$(dirname "$(dirname "$(realpath "$(which "$1")")")")"; }
    function nix-cd()   { cd "$(nix-dir "$1")"; }
    function nix-pkgs() { cd /nix/var/nix/profiles/per-user/root/channels/nixos; }
    function nix()      { command nix --offline "$@"; }
    function vm() {
      # CFILE=/tmp/shared/file
      # sudo touch $CFILE
      # sudo chown ppom $CFILE
      # COUNT=$(tail -n1 $CFILE 2>/dev/null || echo 0)
      # echo $(($COUNT + 1)) >> $CFILE
      # echo
      # cat $CFILE
      # echo
      # sleep 2

      export QEMU_KERNEL_PARAMS=console=ttyS0
      script="$(ls /nix/store/*-nixos-vm/bin/run-pakala-vm | xargs grep -l $(readlink -f /run/current-system))"
      ram=$(grep MemAvailable /proc/meminfo | sed 's/.* \([0-9]*\) .*/\1/')
      # From kB to MB, leave 100MB for "host"
      ram=$(($ram / 1000 - 100))

      exit=1
      while test $exit -ne 0 && test $ram -gt 100
      do
        $script \
          -nographic \
          -m $ram

        exit=$?

        ram=$(($ram - 100))
      done
    }

    free -h
    sleep 1
    vm
  '';

  system.stateVersion = "24.05";

  systemd = {
    enableEmergencyMode = false;
    # Remove systemd-oomd
    oomd.enable = false;
  };

  # Remove systemd user instance
  security.pam.services.login.startSession = lib.mkForce false;

  # Remove nscd
  services.nscd.enable = false;
  system.nssModules = lib.mkForce [ ];

  # remove dbus
  services.dbus.enable = lib.mkForce false;

  # remove logind
  systemd.services.systemd-logind.enable = lib.mkForce false;

  networking = {
    hostName = "pakala"; # Define your hostname.
    firewall.enable = false;
    # Remove dhcp
    dhcpcd.enable = false;
  };

  services.udev.extraRules = ''
    net.ifnames=0
  '';

  time.timeZone = "Europe/Paris";
  i18n.defaultLocale = "en_US.UTF-8";

  boot.tmp.cleanOnBoot = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.ppom = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    initialPassword = "toto";
  };
  # No passwoooooord
  services.getty.autologinUser = "ppom";
  security.sudo.wheelNeedsPassword = false;

  # Hardware configuration
  boot.loader.grub.device = "/dev/sda";
  boot.initrd.kernelModules = [ "nvme" ];
  fileSystems."/" = {
    device = "/dev/sda1";
    fsType = "ext4";
    options = [ "noexec" ];
  };
}
