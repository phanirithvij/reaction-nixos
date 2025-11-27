{
  lib,
  pkgs,
  config,
  ...
}:
# from https://nixos.wiki/wiki/Sway
let
  # bash script to let dbus know about important env variables and
  # propagate them to relevent services run at the end of sway config
  # see
  # https://github.com/emersion/xdg-desktop-portal-wlr/wiki/"It-doesn't-work"-Troubleshooting-Checklist
  # note: this is pretty much the same as  /etc/sway/config.d/nixos.conf but also restarts
  # some user services to make sure they have the correct environment variables
  dbus-sway-environment = pkgs.writeTextFile {
    name = "dbus-sway-environment";
    destination = "/bin/dbus-sway-environment";
    executable = true;

    text = ''
      dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=sway
      systemctl --user stop pipewire pipewire-media-session xdg-desktop-portal xdg-desktop-portal-wlr
      systemctl --user start pipewire pipewire-media-session xdg-desktop-portal xdg-desktop-portal-wlr
    '';
  };

  # currently, there is some friction between sway and gtk:
  # https://github.com/swaywm/sway/wiki/GTK-3-settings-on-Wayland
  # the suggested way to set gtk settings is with gsettings
  # for gsettings to work, we need to tell it where the schemas are
  # using the XDG_DATA_DIR environment variable
  # run at the end of sway config
  configure-gtk =
    let
      schema = pkgs.gsettings-desktop-schemas;
      datadir = "${schema}/share/gsettings-schemas/${schema.name}";
    in
    pkgs.writeShellScriptBin "configure-gtk" ''
      export XDG_DATA_DIRS=${datadir}:$XDG_DATA_DIRS
      gsettings set org.gnome.desktop.interface gtk-theme 'Qogir-Light'
    '';

  rbw-wofi = (
    pkgs.writeShellScriptBin "rbw-wofi" ''
      set -eu
      set -o pipefail
      rbw unlock
      rbw ls --fields folder,name,user | sed 's@\t@/@g' | sort | ${pkgs.wofi}/bin/wofi --dmenu | sed -e 's@.*/\(.*\)/\(.*\)@"\1" "\2"@' -e 's@""@@' | xargs -r rbw get | wl-copy -o
    ''
  );

in
lib.mkMerge [
  {
    environment.systemPackages = with pkgs; [
      wayland

      swaylock
      swayidle
      swaybg
      waybar

      dbus-sway-environment
      configure-gtk
      xdg-utils
      dex # xdg-autostart

      glib # gsettings
      # dracula-theme # gtk theme
      # gruvbox-dark-gtk # gtk theme
      # nordic # gtk theme
      qogir-theme # gtk theme
      adwaita-icon-theme # default gnome cursors

      grim # screenshot functionality
      slurp # screenshot functionality
      wf-recorder # screen recording

      pulseaudio # only for pactl
      wlsunset
      wev

      # easyeffects # audio effects

      wlr-randr # manage displays/monitors

      wl-clipboard # wl-copy and wl-paste for copy/paste from stdin / stdout

      wofi # wayland clone of rofi
      wofi-emoji # wrapper for emoji mode
      wtype # needed by wofi-emoji
      rbw-wofi

      xfce.thunar # file explorer
      xfce.ristretto # image viewer
    ];

    services.pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
    };

    # Enable bluetooth
    services.blueman.enable = true;
    hardware.bluetooth.enable = true;
    hardware.bluetooth.powerOnBoot = false;
    systemd.user.services = {
      blueman-applet.enable = false;
      obex.enable = false;
      "dbus-org.bluez.obex.service".enable = false;
    };

    # xdg-desktop-portal works by exposing a series of D-Bus interfaces
    # known as portals under a well-known name
    # (org.freedesktop.portal.Desktop) and object path
    # (/org/freedesktop/portal/desktop).
    # The portal interfaces include APIs for file access, opening URIs,
    # printing and others.
    services.dbus.enable = true;
    xdg.portal = {
      enable = true;
      wlr.enable = true;
      # gtk portal needed to make gtk apps happy
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
      # needed for plex-desktop, but cause the rest to break
      # xdgOpenUsePortal = true;
    };

    # enable sway window manager
    programs.sway = {
      enable = true;
      wrapperFeatures.gtk = true;
    };

    # enable river window manager
    programs.river = {
      enable = true;
      extraPackages = lib.mkForce [ ];
    };

    # don't need text-to-speech service
    services.speechd.enable = false;

    # Fix of: Can't shutdown after having suspended the laptop by closing it.
    # Fix found here: https://bugs.launchpad.net/ubuntu/+source/systemd/+bug/1441253
    # Sounds like one of the systemd bugs that has never been fixed...
    services.logind.lidSwitch = "suspend-then-hibernate";

    # Try to fix the gnome settings issue
    # Override GSettings schemas
    environment.sessionVariables.NIX_GSETTINGS_OVERRIDES_DIR = "${pkgs.gnome.nixos-gsettings-overrides}/share/gsettings-schemas/nixos-gsettings-overrides/glib-2.0/schemas";

    # This specialisation allows to close the lid without actually suspending the computer
    # specialisation.closeLid.configuration.services.logind.lidSwitch = lib.mkOverride 98 "lock";

    systemd.services.notify-low-battery = {
      description = "Notify on low battery with sound and notification";
      serviceConfig = {
        ExecStart = "${
          pkgs.writeShellApplication {
            name = "check_battery";
            runtimeInputs = with pkgs; [
              libnotify
              pulseaudio
              mpv-no-scripts
            ];
            text = ''
              BAT=${if config.networking.hostName == "sona" then "BAT0" else "BAT1"}
              AC=${if config.networking.hostName == "sona" then "AC" else "ACAD"}

              export DISPLAY=${"\$"}{DISPLAY:=":0"}
              export XDG_RUNTIME_DIR=${"\$"}{XDG_RUNTIME_DIR:=/run/user/$(id -u)}
              export DBUS_SESSION_BUS_ADDRESS=${"\$"}{DBUS_SESSION_BUS_ADDRESS:="unix:path=${"\$"}{XDG_RUNTIME_DIR}/bus"}

              AC_ON="$(cat /sys/class/power_supply/$AC/online)"
              BATTERY_PERCENT="$(cat /sys/class/power_supply/$BAT/capacity)"
              BATTERY_MIN=12

              if [ "$AC_ON" -eq 0 ] && [ "$BATTERY_PERCENT" -le $BATTERY_MIN ]
              then
                    echo "Low battery detected" 1>&2
                    notify-send --urgency=critical --expire-time 3000 "Batterie faible" "$BATTERY_PERCENT% restants"
                    mpvnoscripts /home/"$(id -un)"/.local/files/titi.aac
              else
                    echo "Not low not battery not detected" 1>&2
              fi'';
          }
        }/bin/check_battery";
        User = "ppom";
      };
      startAt = "*-*-* *:0/2:00";
    };

    systemd.services.nixos-upgrade = {
      serviceConfig = {
        ExecStartPre = "/run/wrappers/bin/sudo -u ppom ${
          pkgs.writeShellApplication {
            name = "notify-upgrade";
            runtimeInputs = with pkgs; [ libnotify ];
            text = ''
              export DISPLAY=${"\$"}{DISPLAY:=":0"}
              export XDG_RUNTIME_DIR=${"\$"}{XDG_RUNTIME_DIR:=/run/user/$(id -u)}
              export DBUS_SESSION_BUS_ADDRESS=${"\$"}{DBUS_SESSION_BUS_ADDRESS:="unix:path=${"\$"}{XDG_RUNTIME_DIR}/bus"}
              notify-send --urgency=critical --expire-time 60000 "Mise à jour de NixOS dans 1 minute"
              sleep 1m
            '';
          }
        }/bin/notify-upgrade";
      };
    };

    # Udev rules
    programs.light.enable = true;

    # services.flatpak.enable = true;

    # thunar tumbnail provider
    services.tumbler.enable = true;

    environment.variables.BROWSER = "firefox";
  }
  {
    # Steam
    hardware.graphics = {
      enable32Bit = true;
      extraPackages32 = with pkgs.pkgsi686Linux; [ libva ];
    };
    environment.systemPackages = with pkgs; [
      steam
    ];
  }
  {
    # # Android
    # programs.adb.enable = true;
    # users.users.ppom.extraGroups = [
    #   "adbusers" # for adb & fastboot to work as ppom
    #   "dialout" # for webusb to work on chromium
    # ];
    # programs.sway.extraSessionCommands = ''
    #   # Fix for some Java AWT applications (e.g. Android Studio),
    #   # use this if they aren't displayed properly:
    #   export _JAVA_AWT_WM_NONREPARENTING=1
    # '';
    # environment.systemPackages = with pkgs; [
    #   android-studio
    # ];
    # # WayDroid
    # virtualisation.waydroid.enable = true;
  }
  {
    # Unfree
    # nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) ([ "steam" "steam-original" ] ++ map lib.getName [ pkgs.android-studio ]);
    nixpkgs.config.allowUnfreePredicate =
      pkg:
      builtins.elem (lib.getName pkg) [
        "steam"
        "steam-original"
        "steam-unwrapped"
      ];
  }
]
