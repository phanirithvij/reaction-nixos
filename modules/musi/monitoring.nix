{ config, pkgs, ... }:

let
  VARS= ''
    DATA_DIR="$HOME/.check_co/"
    DATA_FILE="$DATA_DIR/log"
    TEST_HOST="google.fr"
  '';

  check = pkgs.writeShellScriptBin "check_co.sh" ''
    ${VARS}

    ${pkgs.coreutils}/bin/mkdir -p $DATA_DIR

    ${pkgs.inetutils}/bin/ping -c2 -W3 $TEST_HOST &>/dev/null
    STAT=$?

    ${pkgs.coreutils}/bin/echo "$(date +%s) $STAT" | \
    ${pkgs.coreutils}/bin/tee -a $DATA_FILE
  '';

  print = pkgs.writeShellScriptBin "print_co.sh" ''
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
      LogNamespace = "noisy";
    };
    startAt = "minutely";
  };
  # Don't store check-co logging to disk
  environment.etc."systemd/journald@noisy.conf".text = ''
    [Journal]
    Storage=volatile
    RuntimeMaxUse=10M
  '';
}
