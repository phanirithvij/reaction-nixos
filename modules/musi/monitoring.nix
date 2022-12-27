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

  monitPort = "2812";
  monitDestinationMail = "paco@ecomail.io";
  monitFromMail = "musi@ppom.me";
  monitBasicAuthFile = "/var/secrets/basic_auth_nginx/monit";

  systemdCheck = pkgs.writeScript "systemctl-status-ok" ''
      #!${pkgs.runtimeShell}

      ${pkgs.systemd}/bin/systemctl list-units --failed | grep -q "0 loaded units listed"
      if test $? = 0
      then
        exit 0
      fi

      units="$(systemctl list-units --failed | grep ● | cut -d" " -f2)"
      echo "$units"

      for unit in $units
      do
        echo "FAILED: $unit"
        journalctl --no-pager -n 8 -u "$unit" | head -n4
      done
      exit 1
    '';
in {
  services.monit = let
  in {
    enable = true;
    config = ''
      # General Settings
      SET DAEMON 30 # Run checks every 30s
      SET HTTPD PORT ${monitPort} ADDRESS 127.0.0.1 SIGNATURE DISABLE ALLOW MD5 ${monitBasicAuthFile}

      # Mail alerts
      SET ALERT ${monitDestinationMail} WITH REMINDER ON 120 CYCLES # Every 10min
      SET MAILSERVER localhost
      SET MAIL-FORMAT {
      from: Monit <${monitFromMail}>
      subject: $HOST: $EVENT
      message: host:   $HOST
      action: $ACTION
      date:   $DATE
      --
      $DESCRIPTION
      }

      # Standard Checks
      CHECK SYSTEM musi
      CHECK NETWORK musi-ethernet INTERFACE enp6s0

      # System D failed service check
      CHECK PROGRAM systemctl-status PATH ${systemdCheck} TIMEOUT 2 SECONDS
        IF STATUS != 0 THEN ALERT

      # Uploader index.html must be present
      CHECK FILE uploader-index PATH /data/uploader/index.html
        START = "${pkgs.coreutils}/bin/touch /data/uploader/index.html"

      # TEST. Will fail because /data is a directory.
      # CHECK PROGRAM test PATH /data
      #   IF STATUS != 0 THEN ALERT
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

  systemd.services.check-co = {
    description = "Check if internet connection is up";
    serviceConfig.User = "ppom";
    serviceConfig.ExecStart = "${check}/bin/check_co.sh";
    startAt = "minutely";
  };
}
