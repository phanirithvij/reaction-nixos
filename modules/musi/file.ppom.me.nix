{ lib, pkgs, config, ... }:
let
  var = import ../common/reaction-variables.nix { inherit pkgs; };
in {
  services.nextcloud = {
    enable = true;
    enableBrokenCiphersForSSE = false;
    package = pkgs.nextcloud26;
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
      # mail_smtphost = "smtp.ecomail.fr";
      # mail_smtpsecure = "ssl";
      # mail_smtpauthtype = "LOGIN";
      # mail_smtpname     = "paco@ecomail.io";
      # mail_smtppassword = "' . trim(file_get_contents('/var/secrets/mail/ecomail')) . '";
    };
  };

  users.users.nextcloud.extraGroups = [ "postmaster" ];

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

  services.postgresqlBackup.databases = [ "nextcloud" ];

  # ensure that postgres is running *before* running the setup
  systemd.services."nextcloud-setup" = {
    requires = ["postgresql.service"];
    after = ["postgresql.service"];
  };

  services.reaction.settings.streams.nextcloud = {
    cmd = [ var.journalctl "-fn0" "-u" "phpfpm-nextcloud.service" ];
    filters.failedLogin = {
      regex = [
        ''"remoteAddr":"<ip>".*"message":"Login failed:''
        ''"remoteAddr":"<ip>".*"message":"Trusted domain error.''
      ];
      retry = 3;
      retryperiod = "1h";
      actions = var.banFor "1h";
    };
  };

  users.users.cospend-balance = {
    isSystemUser = true;
    group = "cospend-balance";
  };
  users.groups.cospend-balance = {};

  systemd.services.cospend-balance = let
    package = pkgs.callPackage ../../pkgs/cospend-balance {};
    json = pkgs.formats.json {};
    settings = ./cospend-balance.yml;
  in {
    enable = true;
    description = "Sync Nextcloud Cospend bills";
    requires = ["phpfpm-nextcloud.service"];
    after = ["phpfpm-nextcloud.service"];
    startAt = "02:55";
    serviceConfig = {
      User = "cospend-balance";
      Group = "cospend-balance";
      ExecStart = "${package}/bin/cospend-balance -y ${settings}";
    };
  };
}
