{ lib, pkgs, config, ... }:
let
  cfg = {
    enable = true;
    hostname = "onlyoffice.ppom.me";
    jwtSecretFile = "/var/secrets/onlyoffice-jwt";
    # jwtSecretFile = null;
    # default values
    # port = 8000;
    # postgresHost = "/run/postgresql";
    # postgresName = "onlyoffice";
    # postgresUser = "onlyoffice";
    # postgresPasswordFile = null;
    # package = pkgs.onlyoffice-documentserver;
    # rabbitmqUrl = "amqp://guest:guest@localhost:5672";
  };
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

  services.onlyoffice = cfg;

  # Required for onlyoffice
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ "corefonts" ];

  # systemd.services.onlyoffice-docservice.serviceConfig.ExecStartPre = lib.mkForce [
  #   (pkgs.writeShellScript "onlyoffice-prestart" ''
  #     PATH=$PATH:${lib.makeBinPath (with pkgs; [ jq moreutils config.services.postgresql.package ])}
  #     umask 077
  #     mkdir -p /run/onlyoffice/config/ /var/lib/onlyoffice/documentserver/sdkjs/{slide/themes,common}/ /var/lib/onlyoffice/documentserver/{fonts,server/FileConverter/bin}/
  #     cp -r ${cfg.package}/etc/onlyoffice/documentserver/* /run/onlyoffice/config/
  #     chmod u+w /run/onlyoffice/config/default.json

  #     cp /run/onlyoffice/config/default.json{,.orig}

  #     # for a mapping of environment variables from the docker container to json options see
  #     # https://github.com/ONLYOFFICE/Docker-DocumentServer/blob/master/run-document-server.sh
  #     jq '
  #       .services.CoAuthoring.server.port = ${toString cfg.port} |
  #       .services.CoAuthoring.sql.dbHost = "${cfg.postgresHost}" |
  #       .services.CoAuthoring.sql.dbName = "${cfg.postgresName}" |
  #     ${lib.optionalString (cfg.postgresPasswordFile != null) ''
  #       .services.CoAuthoring.sql.dbPass = "'"$(cat ${cfg.postgresPasswordFile})"'" |
  #     ''}
  #       .services.CoAuthoring.sql.dbUser = "${cfg.postgresUser}" |
  #     ${lib.optionalString (cfg.jwtSecretFile != null) ''
  #       .services.CoAuthoring.token.enable.browser = true |
  #       .services.CoAuthoring.token.enable.request.inbox = true |
  #       .services.CoAuthoring.token.enable.request.outbox = true |
  #       .services.CoAuthoring.secret.inbox.string = "'"$(cat ${cfg.jwtSecretFile})"'" |
  #       .services.CoAuthoring.secret.outbox.string = "'"$(cat ${cfg.jwtSecretFile})"'" |
  #       .services.CoAuthoring.secret.session.string = "'"$(cat ${cfg.jwtSecretFile})"'" |
  #     ''}
  #       .rabbitmq.url = "${cfg.rabbitmqUrl}"
  #       ' /run/onlyoffice/config/default.json | sponge /run/onlyoffice/config/default.json

  #     if psql -d onlyoffice -c "SELECT 'task_result'::regclass;" >/dev/null; then
  #       psql -f ${cfg.package}/var/www/onlyoffice/documentserver/server/schema/postgresql/removetbl.sql
  #       psql -f ${cfg.package}/var/www/onlyoffice/documentserver/server/schema/postgresql/createdb.sql
  #     else
  #       psql -f ${cfg.package}/var/www/onlyoffice/documentserver/server/schema/postgresql/createdb.sql
  #     fi
  #   '')
  #   (pkgs.writeShellScript "onlyoffice-custom-settings" ''
  #     ${pkgs.jq}/bin/jq '
  #       .wopi.enable = true |
  #       .wopi.host = "file.ppom.me"
  #     ' /run/onlyoffice/config/default.json | ${pkgs.moreutils}/bin/sponge /run/onlyoffice/config/default.json
  #   '')
  # ];

  # users.users.nextcloud.extraGroups = [ "postmaster" ];

  services.nginx.virtualHosts = {
    "onlyoffice.ppom.me" = {
      enableACME = true;
      forceSSL = true;
    };
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
}
