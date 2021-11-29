{ lib, config, pkgs, ... }:
let
  websites = [
    "https://ppom.me"
    "https://video.ppom.me"
    "https://music.ppom.me"
    "https://blog.ppom.me"
    "https://u.ppom.me"
    "https://nuage.ppom.me"
  ];
  dns_test = "dns2.proxad.net";
  log_file = "/home/ao/DOWN";
  down_detector = pkgs.writeScript "down_detector.sh" ''
    #!${pkgs.bash}/bin/bash

    LOG_FILE="${log_file}"

    SITES="${lib.concatStringsSep " " websites}"

    # First check general internet connectivity
    if ${pkgs.inetutils}/bin/ping -c 1 -W 3 ${dns_test} &>/dev/null
    then

        DIR="$(${pkgs.coreutils}/bin/mktemp -d)"
        cd "$DIR" || exit 1
        FAIL=0

        for site in $SITES
        do
            ${pkgs.curl}/bin/curl -s -o /dev/null "$site"
            STATUS=$?
            if [[ $STATUS -ne 0 ]]
            then
                echo "$(date): $site is down! curl code = $STATUS" >> "$LOG_FILE"
                FAIL=1
            fi
        done

        ${pkgs.coreutils}/bin/rm -r "$DIR"
        exit $FAIL

    else
      exit 3
    fi
  '';
in
{
  environment.systemPackages = [ down_detector ];

  systemd.timers.down_detector = {
    wantedBy = [ "timers.target" ];
    after = [ "network.target" ];
    timerConfig = {
      # OnCalendar = "*-*-* *:*:00";
      OnCalendar = "minutely";
    };
  };
  systemd.services.down_detector = {
    description = "check if some websites are down";
    serviceConfig = {
      ExecStart = down_detector;
      User = "ao";
    };
  };
}
