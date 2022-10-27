{ config, pkgs, ... }:

let
  VARS= ''
    DATA_DIR="$HOME/.check_co/"
    DATA_FILE="$DATA_DIR/log"
    TEST_HOST="google.fr"
  '';

  check = pkgs.writeScriptBin "check_co.sh" ''
    #!${pkgs.bash}/bin/bash

    ${VARS}

    ${pkgs.coreutils}/bin/mkdir -p $DATA_DIR

    ${pkgs.inetutils}/bin/ping -c2 -W3 $TEST_HOST &>/dev/null
    STAT=$?

    ${pkgs.coreutils}/bin/echo "$(date +%s) $STAT" | \
    ${pkgs.coreutils}/bin/tee -a $DATA_FILE
  '';

  print = pkgs.writeScriptBin "print_co.sh" ''
    #!${pkgs.bash}/bin/bash

    ${VARS}

    # Print only first column of lines non ending with zero code
    # | Print the timestamp in a human-readable format
    ${pkgs.gawk}/bin/awk '! / 0$/ { print $1 }' $DATA_FILE | \
    ${pkgs.findutils}/bin/xargs -d'\n' -I'{}' date -d'@{}'
  '';

  monitPort = "2812";
  monitMail = "paco@ecomail.io";
  monitBasicAuthFile = "/var/secrets/basic_auth_nginx/monit";

  systemdCheck = ''${pkgs.writeShellApplication {
    name = "systemctl-status-ok";
    runtimeInputs = [ pkgs.systemd ];
    text = ''
      systemctl list-units --failed | grep -q "0 loaded units listed"
      exit $?
    '';
  }}/bin/systemctl-status-ok'';
in {
  services.monit = let
  in {
    enable = true;
    config = ''
      # General Settings
      SET DAEMON 30 # Run checks every 30s
      SET HTTPD PORT ${monitPort} ADDRESS 127.0.0.1 SIGNATURE DISABLE ALLOW MD5 ${monitBasicAuthFile}

      # Mail alerts
      SET ALERT ${monitMail} WITH REMINDER ON 120 CYCLES # Every 10min
      SET MAILSERVER localhost

      # Standard Checks
      CHECK SYSTEM musi
      CHECK NETWORK musi-ethernet INTERFACE enp6s0

      # System D failed service check
      CHECK PROGRAM systemctl-status PATH ${systemdCheck} TIMEOUT 2 SECONDS
        IF STATUS != 0 THEN ALERT
    '';
  };

  services.nginx.virtualHosts."ppom.me" = {
    forceSSL = true;
    enableACME = true;
    locations."/monit/" = {
      # trailing / indicates that the "/monit/" prefix should be removed
      proxyPass = "http://localhost:${monitPort}/";
      # extraConfig = ''auth_basic "Credentials"; auth_basic_user_file ${monitBasicAuthFile};'';
    };
  };

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

  systemd.timers.check-co = {
    description = "Check if internet connection is up";
    wantedBy = [ "timers.target" ];
    timerConfig.OnCalendar = "minutely";
  };
  systemd.services.check-co = {
    description = "Check if internet connection is up";
    serviceConfig.User = "ppom";
    serviceConfig.ExecStart = "${check}/bin/check_co.sh";
  };
}
