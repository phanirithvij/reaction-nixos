{ lib, config, pkgs, ... }:
lib.mkMerge [
  # Nextcloud
  {
    services.nextcloud = {
      enable = true;
      package = pkgs.nextcloud31;
      configureRedis = true;
      autoUpdateApps.enable = true;
      hostName = "file.ppom.me";
      https = true;
      database.createLocally = true;
      config = {
        dbtype = "pgsql";
        adminpassFile = "/var/secrets/file/admin";
        adminuser = "admin";
      };
      # settings = {
      #   mail_smtpmode = "smtp";
      #   mail_smtphost = "mail.girofle.org";
      #   mail_smtpsecure = "ssl";
      #   mail_smtpauthtype = "LOGIN";
      #   mail_smtpname     = "file@ppom.me";
      #   mail_smtppassword = "' . trim(file_get_contents('/var/secrets/mail/file@ppom.me')) . '";
      # };
      maxUploadSize = "10G";
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

    services.nginx.virtualHosts = {
      "file.ppom.me" = {
        enableACME = true;
        forceSSL = true;
      };
      "board.ppom.me" = {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://localhost:3002";
          proxyWebsockets = true;
        };
      };
      # "edition.ppom.me" = let
      #   pass = {
      #     proxyPass = "http://localhost:9980";
      #   };
      # in {
      #   enableACME = true;
      #   forceSSL = true;
      #   locations = {
      #     "/browser" = pass;
      #     "/hosting/discovery" = pass;
      #     "/hosting/capabilities" = pass;
      #     "/cool/adminws" = pass;
      #     "/cool" = pass;
      #     "/cool/.*/ws" = pass // {
      #       proxyWebsockets = true;
      #     };
      #   };
      # };
    };

    # services.collabora-online = {
    #   enable = true;
    #   settings = {
    #     net.listen = "127.0.0.1";
    #     storage.wopi.alias_groups.group.host = {
    #       "@allow" = true;
    #     };
    #   };
    # };

    services.nextcloud-whiteboard-server = {
      enable = true;
      secrets = [ "/var/secrets/whiteboard" ];
      settings.NEXTCLOUD_URL = "https://file.ppom.me";
    };

    services.postgresqlBackup.databases = [ "nextcloud" ];

    services.reaction.settings.streams.nextcloud = let
      var = import ../common/reaction-variables.nix { inherit config pkgs; };
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

  # sudo workaround for nextcloud-occ
  # (let
  #   execstart = lib.splitString " " config.systemd.services.nextcloud-cron.serviceConfig.ExecStart;
  #   php = "${lib.head execstart}";
  #   webroot = builtins.dirOf (lib.elemAt execstart 2);
  # in {
  #   environment.systemPackages = [
  #     (lib.hiPrio (pkgs.writeShellScriptBin "nextcloud-occ" ''
  #       cd ${webroot}
  #       exec /run/wrappers/bin/sudo \
  #         -u nextcloud \
  #         NEXTCLOUD_CONFIG_DIR="/var/lib/nextcloud/config" \
  #         ${php} occ "$@"
  #     ''))
  #   ];
  #   security.sudo.extraRules = [ {
  #     cmd = php;
  #     setEnv = [ "NEXTCLOUD_CONFIG_DIR" ];
  #     runAs = "nextcloud";
  #     groups = [ "wheel" ];
  #   } ];
  # })

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
