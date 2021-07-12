{ lib, pkgs, config, ... }:
with lib;                      
let
  cfg = config.services.rzw;
  rzwPackage = pkgs.callPackage ../../pkgs/rzw/default.nix {};
in {
  options.services.rzw = {
    enable = mkEnableOption "enable RuleZeWorld";
    domain = mkOption {
      type = types.str;
      description = "Domain you want to use";
    };
    user = mkOption {
      type = types.str;
      description = "System user's name";
      default = "rzw";
    };
    userDir = mkOption {
      type = types.str;
      description = "System user's home";
      default = "/var/lib/rzw";
    };
    musicDir = mkOption {
      type = types.str;
      description = "Public music directory. Must be readable by nginx";
      default = "${cfg.userDir}/music";
    };
    sqliteFile = mkOption {
      type = types.str;
      description = "Path to the sqlite file to use";
      default = "${cfg.userDir}/rzw.db";
    };
    adminPasswordFile = mkOption {
      type = types.str;
      description = "Path to a file containing the admin password";
    };
  };

  config = mkIf cfg.enable {
    users = {
      users."${cfg.user}" = {
        isSystemUser = true;
        packages = with pkgs; [];
        home = cfg.userDir;
        group = cfg.user;
      };
      groups."${cfg.user}" = {};
    };
    services.phpfpm.pools.rzw = {
      user = cfg.user;
      settings = {
        "listen.owner" = config.services.nginx.user;
        "pm" = "dynamic";
        "pm.max_children" = 4;
        "pm.max_requests" = 50;
        "pm.start_servers" = 2;
        "pm.min_spare_servers" = 2;
        "pm.max_spare_servers" = 3;
        "php_admin_value[error_log]" = "stderr";
        "php_admin_flag[log_errors]" = true;
        "catch_workers_output" = true;
        # FIXME Warning! DEV only!
        "php_flag[display_errors]" = true;
      };
      phpEnv = {
        RZW_DB_FILE = cfg.sqliteFile;
        RZW_ADMIN_PASSWORD_FILE = cfg.adminPasswordFile;
      };
    };
    systemd.services."rzw-init" = {
      enable = true;
      description = "Ensures rzw's SQLite database exists";
      requiredBy = [ "phpfpm-rzw.service" ];

      path = with pkgs; [ sqlite ];

      # unitConfig = {
      #   ConditionPathExists = "!${cfg.sqliteFile}";
      # };

      serviceConfig = {
        Type = "oneshot";
        User = "root";
      };

      script = ''
        set -e
        SQL="${cfg.sqliteFile}"
        DIR="$(dirname "$SQL")"

        [ -d "$DIR" ] || mkdir "$DIR"
        chown "${cfg.user}" "$DIR"
        chmod 755 "$DIR"

        sqlite3 "$SQL" < ${rzwPackage}/misc/sqlite.init.sql
        chown "${cfg.user}" "$SQL"
        chmod 600 "$SQL"
      '';
    };

    services.nginx.virtualHosts."${cfg.domain}" = {
      forceSSL = true;
      enableACME = true;
      root = "${rzwPackage.outPath}/public";
      locations = {
        "/" = {
          tryFiles = "$uri $uri.html $uri/ =404";
        };
        "/login" = {
          return = "301 https://$host";
        };
        "~ \.php$" = {
          extraConfig = ''
            fastcgi_split_path_info ^(.+\.php)(/.+)$;
            fastcgi_pass unix:${config.services.phpfpm.pools.rzw.socket};
            include ${pkgs.nginx}/conf/fastcgi_params;
            include ${pkgs.nginx}/conf/fastcgi.conf;
          '';
        };
      };
      extraConfig = ''
        # add_header Strict-Transport-Security "max-age=31536000";
      '';
    };
  };
}
