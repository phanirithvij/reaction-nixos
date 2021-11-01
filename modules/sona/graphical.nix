{ lib, config, pkgs, ... }:
{
  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;
    enableCtrlAltBackspace = true;
    layout = "fr";
    # Enable touchpad support.
    libinput.enable = true;
    # use dwm
    windowManager.dwm.enable = true;
    # configure LightDM
    displayManager = {
      lightdm.enable = true;
      lightdm.greeter.enable = false;
      # autoLogin
      autoLogin.enable = true;
      autoLogin.user = "ao";
    };
    # The dots per inch of my screen.
    dpi = 96;
  };

  ### BEGIN UNFREE
  # Yeah, I'm not proud of that
  nixpkgs.config.allowUnfree = true;
  # nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ "steam" "nvidia" ];

  # Nvidia driver
  # services.xserver.videoDrivers = [ "nvidia" ];

  # Steam related
  environment.systemPackages = [ pkgs.steam ];
  hardware.opengl.driSupport32Bit = true;
  hardware.opengl.extraPackages32 = with pkgs.pkgsi686Linux; [ libva ];
  hardware.pulseaudio.support32Bit = true;
  ### END UNFREE

  # Fix of: Can't shutdown after having suspended the laptop by closing it.
  # Fix found here: https://bugs.launchpad.net/ubuntu/+source/systemd/+bug/1441253
  # Sounds like one of the systemd bugs that has never been fixed...
  services.logind.lidSwitch = "suspend-then-hibernate";

  # This specialisation allows to close the lid without actually suspending the computer
  specialisation.closeLid.configuration.services.logind.lidSwitch = lib.mkOverride 98 "lock";

  # setuid wrapper for slock
  programs.slock.enable = true;

  # Cron jobs
  services.cron = {
    enable = true;
    cronFiles = [
      ''${pkgs.writeText "ao.crontab" ''
        */30 * * * * ao /home/ao/bin/change_wallpaper.fish
      ''}''
    ];
  };

  # Programs
  programs = {
    # Udev rules
    light.enable = true;

    xss-lock = {
      enable = true;
      lockerCommand = "/run/wrappers/bin/slock";
    };

    gnupg.agent = {
      pinentryFlavor = "gnome3";
    };

  };

  # Flatpak
  services.flatpak.enable = true;
  xdg.portal.enable = true;

  environment.variables.BROWSER = "firefox";

}
