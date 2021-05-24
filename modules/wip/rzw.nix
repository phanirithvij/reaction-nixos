{ lib, pkgs, config, ... }:
with lib;                      
let
  cfg = config.services.rzw;
  rzwPackage = callPackage ../../pkgs/rzw/default.nix;
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
    sqliteFile = mkOption {
      type = types.str;
      description = "Path to the sqlite file to use";
      default = "/var/lib/rzw/rzw.db";
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
      };
      # phpEnv."PATH" = lib.makeBinPath [ pkgs.php ];
      phpEnv."RZW_DB_FILE" = cfg.sqliteFile;
      phpEnv."RZW_ADMIN_PASSWORD_FILE" = cfg.adminPasswordFile
    };
    systemd.services."rzw-dir-exists" = {
      enable = true;
      description = "Ensures rzw's SQLite database exists";
      requiredBy = [ "phpfpm-rzw.service" ];

      unitConfig = {
        ConditionPathExists = "!${cfg.sqliteFile}";
      };

      serviceConfig = {
        Type = "oneshot";
        User = "root";
      };
      script = ''
        SQL="${cfg.sqliteFile}"
        DIR="$(basename "$SQL")"

        mkdir -p "$DIR"
        chmod 755 "$DIR"

        touch "$SQL"
        chown ${cfg.user} "$SQL"
        chmod 600 "$SQL"
      '';
    };
    services.nginx.virtualHosts."${cfg.domain}" = {
      forceSSL = true;
      enableACME = true;
      root = rzwPackage;
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
        add_header Strict-Transport-Security "max-age=31536000";
      '';
    };
  };
}
