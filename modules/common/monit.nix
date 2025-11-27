{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.ppom.monit;
in
{
  options.ppom.monit = {
    enable = lib.mkEnableOption "enable Monit with ppom conf";

    fromMail = lib.mkOption {
      type = lib.types.str;
      description = "Which email address Monit must put in FROM";
    };

    destinationMail = lib.mkOption {
      type = lib.types.str;
      description = "Which email address Monit must send emails to";
      default = "monit@ppom.me";
    };

    interface = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      description = "Which network interface to monitor";
      default = null;
    };

    mailServer = lib.mkOption {
      type = lib.types.str;
      description = "mail server";
      default = "mail.girofle.org";
    };

    mailAccount = lib.mkOption {
      type = lib.types.str;
      description = "mail account";
      default = cfg.fromMail;
    };

    mailAccountPasswordFile = lib.mkOption {
      type = lib.types.path;
      description = "file containing the password";
      default = "/var/secrets/mail/${cfg.fromMail}";
    };
  };

  config =
    let
      systemdCheck = pkgs.writeShellScript "systemctl-status-ok" ''
        ${config.systemd.package}/bin/systemctl list-units --failed | grep -q "0 loaded units listed"
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
    in
    lib.mkIf cfg.enable {
      services.monit = {
        enable = true;
        config = ''
          # General Settings
          SET DAEMON 30 # Run checks every 30s

          # Mail alerts
          SET ALERT ${cfg.destinationMail} WITH REMINDER ON ${
            builtins.toString (2 * 60 * 24)
          } CYCLES # Every 24h
          SET MAILSERVER ${cfg.mailServer} PORT 465 USING SSL USERNAME ${cfg.mailAccount} PASSWORD @@PASSWORD@@
          SET MAIL-FORMAT {
          from: Monit <${cfg.fromMail}>
          subject: $HOST: $EVENT
          message: host:   $HOST
          action: $ACTION
          date:   $DATE
          --
          $DESCRIPTION
          }

          SET SSL OPTIONS {
            VERIFY: ENABLE
          }

          # Standard Checks
          CHECK SYSTEM $HOST
          ${lib.optionalString (cfg.interface != null) "CHECK NETWORK ethernet INTERFACE ${cfg.interface}"}

          # System D failed service check
          CHECK PROGRAM systemctl-status PATH ${systemdCheck} TIMEOUT 2 SECONDS
            IF STATUS != 0 THEN ALERT
        '';
      };

      systemd.services.monit.serviceConfig.ExecStartPre = pkgs.writeShellScript "monit-start-pre" ''
        sed -i "s/@@PASSWORD@@/$(cat ${cfg.mailAccountPasswordFile})/" /etc/monitrc
      '';
    };
}
