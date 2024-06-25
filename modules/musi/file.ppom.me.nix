{ lib, pkgs, config, ... }:
lib.mkMerge [
  # Nextcloud
  {
    services.nextcloud = {
      enable = true;
      package = pkgs.nextcloud28;
      configureRedis = true;
      autoUpdateApps.enable = true;
      hostName = "file.ppom.me";
      https = true;
      database.createLocally = true;
      config = {
        dbtype = "pgsql";
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
      poolSettings = /* config.services.nextcloud.poolSettings.default // */ {
        "pm" = "dynamic";
        "pm.max_children" = "32";
        "pm.start_servers" = "4";
        "pm.min_spare_servers" = "2";
        "pm.max_spare_servers" = "4";
        "pm.max_requests" = "500";
      };
      phpOptions = {
        "opcache.interned_strings_buffer" = "12";
      };
      fastcgiTimeout = 360; # for NextPush: UnifiedPush Provider
    };

    users.users.nextcloud.extraGroups = [ "postmaster" ];

    services.nginx.virtualHosts = {
      "file.ppom.me" = {
        enableACME = true;
        forceSSL = true;
      };
    };

    services.postgresqlBackup.databases = [ "nextcloud" ];

    services.reaction.settings.streams.nextcloud = let
      var = import ../common/reaction-variables.nix { inherit pkgs; };
    in {
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
  }

  # doas/sudo workaround for nextcloud-occ
  (let
    execstart = lib.splitString " " config.systemd.services.nextcloud-cron.serviceConfig.ExecStart;
    php = "${lib.head execstart}";
    webroot = builtins.dirOf (lib.elemAt execstart 2);
  in {
    environment.systemPackages = [
      (lib.hiPrio (pkgs.writeShellScriptBin "nextcloud-occ" ''
        cd ${webroot}
        export NEXTCLOUD_CONFIG_DIR="/var/lib/nextcloud/config"
        exec /run/wrappers/bin/doas -u nextcloud ${php} occ "$@"
      ''))
    ];
    security.doas.extraRules = [ {
      cmd = php;
      setEnv = [ "NEXTCLOUD_CONFIG_DIR" ];
      runAs = "nextcloud";
      groups = [ "wheel" ];
    } ];
  })

  # Cospend balance
  {
    users.users.cospend-balance = {
      isSystemUser = true;
      group = "cospend-balance";
    };
    users.groups.cospend-balance = {};

    systemd.services.cospend-balance = let
      package = pkgs.callPackage ../../pkgs/cospend-balance {};
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
]
