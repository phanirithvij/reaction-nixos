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
  # services.cron = {
  #   enable = true;
  #   cronFiles = [
  #     ''${pkgs.writeText "ao.crontab" ''
  #       */30 * * * * ao /home/ao/bin/change_wallpaper.fish
  #     ''}''
  #   ];
  # };

  systemd.timers.notify-low-battery = {
    wantedBy = [ "timers.target" ];
    after = [ "grapical.target" ];
    timerConfig = {
      # every 2 minutes
      OnCalendar = "*-*-* *:0/2:00";
    };
  };
  systemd.services.notify-low-battery = {
    description = "Notify on low battery with sound and notification";
    serviceConfig = {
      ExecStart = "${pkgs.writeShellApplication {
        name = "check_battery";
        runtimeInputs = with pkgs; [ libnotify espeak pulseaudio mpv-no-scripts ];
        text = ''
          export DISPLAY=${"\$"}{DISPLAY:=":0"}
          export XDG_RUNTIME_DIR=${"\$"}{XDG_RUNTIME_DIR:=/run/user/$(id -u)}
          export DBUS_SESSION_BUS_ADDRESS=${"\$"}{DBUS_SESSION_BUS_ADDRESS:="unix:path=${"\$"}{XDG_RUNTIME_DIR}/bus"}

          AC_ON="cat /sys/class/power_supply/AC/online"
          BATTERY_PERCENT="$(cat /sys/class/power_supply/BAT0/capacity)"
          BATTERY_MIN=12

          if [ "$($AC_ON)" -eq 0 ] && [ "$BATTERY_PERCENT" -le $BATTERY_MIN ]
          then
                echo "Low battery detected" 1>&2
                notify-send --urgency=critical --expire-time 3000 "Batterie faible" "$BATTERY_PERCENT% restants"
                mpvnoscripts /home/"$(id -un)"/.local/files/titi.aac
          else
                echo "Not low not battery not detected" 1>&2
          fi'';
        }
      }/bin/check_battery";
      User = "ao";
    };
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
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  environment.variables.BROWSER = "firefox";

  xdg.mime = let
    mails = "thunderbird.desktop";
    images = "feh.desktop";
    videos = "mpv.desktop";
    web = "firefox.desktop";
    pdfs = "org.gnome.Evince.desktop;";
    bittorrent = "deluge.desktop";
    filemanager = "pcmanfm.desktop";
  in {
    defaultApplications = {
      "inode/directory" = filemanager;
      "application/pdf" = pdfs;
      "image/jpeg" = images;
      "image/jpg" = images;
      "image/png" = images;
      "image/gif" = web;
      "video/ogg" = videos;
      "video/mp4" = videos;
      "video/webm" = videos;
      "video/mkv" = videos;
      "video/avi" = videos;
      "text/html" = web;
      "x-scheme-handler/http" = web;
      "x-scheme-handler/https" = web;
      "x-scheme-handler/mailto" = mails;
      "message/rfc822" = mails;
      "x-scheme-handler/feed" = mails;
      "application/rss+xml" = mails;
      "application/x-extension-rss" = mails;
    };
    addedAssociations = {
      "application/x-bittorrent" = bittorrent;
      "x-scheme-handler/mailto" = mails;
      "message/rfc822" = mails;
      "application/pdf" = pdfs;
      "x-scheme-handler/feed" = mails;
      "application/rss+xml" = mails;
      "application/x-extension-rss" = mails;
      "video/ogg" = videos;
      "video/mp4" = videos;
      "video/webm" = videos;
      "video/mkv" = videos;
      "video/avi" = videos;
      "text/html" = web;
      "x-scheme-handler/http" = web;
      "x-scheme-handler/https" = web;
    };
  };

}
