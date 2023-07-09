{ config, pkgs, ... }:

let
  VARS= ''
    DATA_DIR="$HOME/.check_co/"
    DATA_FILE="$DATA_DIR/log"
    TEST_HOST="google.fr"
  '';

  check = pkgs.writeScriptBin "check_co.sh" ''
    #!${pkgs.runtimeShell}

    ${VARS}

    ${pkgs.coreutils}/bin/mkdir -p $DATA_DIR

    ${pkgs.inetutils}/bin/ping -c2 -W3 $TEST_HOST &>/dev/null
    STAT=$?

    ${pkgs.coreutils}/bin/echo "$(date +%s) $STAT" | \
    ${pkgs.coreutils}/bin/tee -a $DATA_FILE
  '';

  print = pkgs.writeScriptBin "print_co.sh" ''
    #!${pkgs.runtimeShell}

    ${VARS}

    # Print only first column of lines non ending with zero code
    # | Print the timestamp in a human-readable format
    ${pkgs.gawk}/bin/awk '! / 0$/ { print $1 }' $DATA_FILE | \
    ${pkgs.findutils}/bin/xargs -d'\n' -I'{}' date -d'@{}'
  '';
in {
  services.vnstat.enable = true;

  environment.etc."vnstat.conf".text = ''
    Interface enp6s0

    # Daemon

    BandwithDetection 1

    PollInterval 5

    TrafficlessEntries 1
    TopDayEntries 0

    5MinutesHours 168
    HourlyDays -1
    DailyDays -1
    MonthlyMonths -1
    YearlyYears -1

    # Output
  '';

  environment.systemPackages = [ check print ];

  systemd.services.check-co = {
    description = "Check if internet connection is up";
    serviceConfig = {
      User = "ppom";
      ExecStart = "${check}/bin/check_co.sh";
      LogNamespace = "trash";
    };
    startAt = "minutely";
  };

  services.netdata = {
    enable = true;
    config = {
      global = {
        "update every" = 10;
      };
    };
    configDir = {
      ".opt-out-from-anonymous-statistics" = pkgs.writeText "empty" "";
    };
  };
  services.nginx.virtualHosts."ppom.me".locations= {
    "/netdata".return = "301 /netdata/";
    "/netdata/" = {
      proxyPass = "http://localhost:19999/";
      proxyWebsockets = true;
      extraConfig = ''
        auth_basic "Credentials";
        auth_basic_user_file /var/secrets/basic_auth_nginx/monit;
      '';
    };
  };
}
