{ lib, config, pkgs, ... }:
let
  websites = [
    "https://blog.ppom.me"
    "https://cours.ppom.fr"
    "https://edit.ppom.fr"
    "https://edit.ppom.me/leborddeleau/admin"
    "https://edit.ppom.me/pompeani.art/admin"
    "https://fesse.cloud"
    "https://file.ppom.me"
    "https://lili-bel.com"
    "https://music.ppom.me"
    "https://paris-loyers.fr"
    "https://pompeani.art"
    "https://ppom.fr"
    "https://ppom.me"
    "https://ppom.me/vault"
    "https://static.ppom.me"
    "https://tokipona.ppom.me"
    "https://u.ppom.me"
    "https://video.ppom.me"
  ];
  dns_test = "dns2.proxad.net";
  log_file = "/home/ao/DOWN";
  down_detector = pkgs.writeShellScriptBin "down_detector.sh" ''
    export DISPLAY=${"\$"}{DISPLAY:=":0"}
    export XDG_RUNTIME_DIR=${"\$"}{XDG_RUNTIME_DIR:=/run/user/$(id -u)}
    export DBUS_SESSION_BUS_ADDRESS=${"\$"}{DBUS_SESSION_BUS_ADDRESS:="unix:path=${"\$"}{XDG_RUNTIME_DIR}/bus"}
    LOG_FILE="${log_file}"

    SITES="${lib.concatStringsSep " " websites}"

    # First check general internet connectivity
    if /run/current-system/sw/bin/ping -c 1 -W 3 ${dns_test} &>/dev/null
    then

        DIR="$(${pkgs.coreutils}/bin/mktemp -d)"
        cd "$DIR" || exit 1
        FAIL=0

        for site in $SITES
        do
            ${pkgs.curl}/bin/curl --retry 3 --retry-all-errors --fail --silent -o /dev/null "$site"
            STATUS=$?
            if [[ $STATUS -ne 0 ]]
            then
                echo "$(date): $site is down! curl code = $STATUS" >> "$LOG_FILE"
                ${pkgs.libnotify}/bin/notify-send --urgency=critical --expire-time 3000 "$site is down!" "curl code = $STATUS"
            fi
        done

        ${pkgs.coreutils}/bin/rm -r "$DIR"
    fi
  '';
in
{
  environment.systemPackages = [ pkgs.inetutils down_detector ];

  systemd.services.down_detector = {
    description = "check if some websites are down";
    serviceConfig = {
      ExecStart = "${down_detector}/bin/down_detector.sh";
      User = "ao";
    };
    startAt = "minutely";
  };
}
