{ lib, config, pkgs, ... }:
let
  websites = [
    "https://video.ppom.me"
    "https://music.ppom.me"
    "https://file.ppom.me"
    "https://akesi.ppom.me"
  ];
  dns_test = "dns2.proxad.net";
  log_file = "/home/ao/DOWN";
  down_detector = pkgs.writeShellScriptBin "down_detector.sh" ''
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
