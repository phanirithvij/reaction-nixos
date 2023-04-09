{ lib, config, pkgs, ... }:
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
  configure-gtk = let
    schema = pkgs.gsettings-desktop-schemas;
    datadir = "${schema}/share/gsettings-schemas/${schema.name}";
  in pkgs.writeScriptBin "configure-gtk" ''
    export XDG_DATA_DIRS=${datadir}:$XDG_DATA_DIRS
    gnome_schema=org.gnome.desktop.interface
    gsettings set $gnome_schema gtk-theme 'Sweet-Dark'
  '';

  rbw-wofi = (pkgs.writeScriptBin "rbw-wofi" ''
    #!${pkgs.runtimeShell}
    set -eu
    set -o pipefail
    rbw unlock
    rbw ls --fields folder,name,user | sed 's/\t/\//g' | sort | ${pkgs.wofi}/bin/wofi --dmenu | sed 's/^[^\/]*\///' | sed 's/\// /' | xargs -r rbw get | wl-copy -o
  '');
  passwofi = (pkgs.writeScriptBin "passwofi" ''
    #${pkgs.runtimeShell}
    shopt -s nullglob globstar

    prefix=$\{PASSWORD_STORE_DIR-~/.password-store}
    password_files=( "$prefix"/**/*.gpg )
    password_files=( "${"\$"}{password_files[@]#"$prefix"/}" )
    password_files=( "${"\$"}{password_files[@]%.gpg}" )

    password=$(printf '%s\n' "${"\$"}{password_files[@]}" | ${pkgs.wofi}/bin/wofi --dmenu "$@")

    [[ -n $password ]] || exit

    ${pkgs.pass}/bin/pass show | wl-copy -o
  '');

in
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
    sweet # gtk theme
    gnome3.adwaita-icon-theme # default gnome cursors

    grim # screenshot functionality
    slurp # screenshot functionality

    pulseaudio # only for pactl
    wlsunset
    wev

    conky # status bar
    kanshi # auto change randr

    wlr-randr # manage displays/monitors
    wl-clipboard # wl-copy and wl-paste for copy/paste from stdin / stdout
    wofi # wayland clone of rofi
    wofi-emoji # wrapper for emoji mode

    rbw-wofi
    passwofi

    steam
  ];

  nixpkgs.overlays = [
    (self: super: {
      conky = super.conky.override { pulseSupport = true; };
      sweet = super.sweet.overrideAttrs (oldAttrs: {
        patches = [ ./sweet-theme.patch ];
      });
    })
  ];

  sound.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  # Enable bluetooth
  services.blueman.enable = true;
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = false;

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
  };

  # enable sway window manager
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
  };

  # Steam related
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ "steam"  "steam-original" ];
  hardware.opengl = {
    driSupport32Bit = true;
    extraPackages32 = with pkgs.pkgsi686Linux; [ libva ];
  };

  # Fix of: Can't shutdown after having suspended the laptop by closing it.
  # Fix found here: https://bugs.launchpad.net/ubuntu/+source/systemd/+bug/1441253
  # Sounds like one of the systemd bugs that has never been fixed...
  services.logind.lidSwitch = "suspend-then-hibernate";

  # This specialisation allows to close the lid without actually suspending the computer
  specialisation.closeLid.configuration.services.logind.lidSwitch = lib.mkOverride 98 "lock";

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
    startAt = "*-*-* *:0/2:00";
  };

  # Programs
  programs = {
    # Udev rules
    light.enable = true;
    gnupg.agent = {
      pinentryFlavor = "gnome3";
    };
  };

  services.flatpak.enable = true;

  environment.variables.BROWSER = "firefox";
}
