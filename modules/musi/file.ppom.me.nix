{ lib, pkgs, config, ... }:
let
  nextcloudFail2banFilter = pkgs.writeText "nextcloudFail2banFilter" ''
    [Definition]
    failregex = "remoteAddr":"<HOST>".*"message":"Login failed:
                "remoteAddr":"<HOST>".*"message":"Trusted domain error.
  '';
in {
  services.nextcloud = {
    enable = true;
    enableBrokenCiphersForSSE = false;
    package = pkgs.nextcloud25;
    autoUpdateApps.enable = true;
    hostName = "file.ppom.me";
    https = true;
    config = {
      dbtype = "pgsql";
      dbuser = "nextcloud";
      dbhost = "/run/postgresql"; # nextcloud will add /.s.PGSQL.5432 by itself
      dbname = "nextcloud";
      adminpassFile = "/var/secrets/file/admin";
      adminuser = "admin";
      # Not possible because services.nextcloud.config is not of freeform type
      # mail_smtpmode = "smtp";
      # mail_smtphost = "mail.ppom.me:465";
      # mail_smtpsecure = "ssl";
      # mail_smtpauthtype = "LOGIN";
      # mail_smtpname     = "postmaster@ppom.me";
      # mail_smtppassword = "' . file_get_contents('/var/secrets/mail/postmaster') . '";
    };
  };

  services.nginx.virtualHosts = {
    "file.ppom.me" = {
      enableACME = true;
      forceSSL = true;
    };
  };

  services.postgresql = {
    enable = true;
    ensureDatabases = [ "nextcloud" ];
    ensureUsers = [ {
      name = "nextcloud";
      ensurePermissions."DATABASE nextcloud" = "ALL PRIVILEGES";
    } ];
  };

  # ensure that postgres is running *before* running the setup
  systemd.services."nextcloud-setup" = {
    requires = ["postgresql.service"];
    after = ["postgresql.service"];
  };

  # Fail2ban
  environment.etc."fail2ban/filter.d/nextcloud.conf".source = nextcloudFail2banFilter;

  services.fail2ban = {
    enable = true;
    jails.nextcloud = ''
      enabled = true
      port = 80,443

      filter = nextcloud
      journalmatch = _SYSTEMD_UNIT=phpfpm-nextcloud.service + _COMM=phpfpm-nextcloud

      maxretry = 3
      bantime = 3600
      findtime = 3600
    '';
  };

  systemd.services.fail2ban.restartTriggers = [ nextcloudFail2banFilter ];
}
