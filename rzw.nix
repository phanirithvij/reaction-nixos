{ lib, pkgs, config, ... }:
with lib;                      
let
  cfg = config.services.rzw;
in {
  options.services.rzw = {
    enable = mkEnableOption "enable RuleZeWorld. Non pure, beware!";
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
      description = "Home of user";
      default = "/var/lib/rzw";
    };
    rootDir = mkOption {
      type = types.str;
      description = "Root dir to serve";
      default = "${config.services.rzw.userDir}/www";
    };
    # sqliteFile = mkOption {
    #   type = types.str;
    #   description = "Path to the sqlite file to use";
    #   default = "${config.services.rzw.userDir}/rzw.db";
    # };
    # envFile = mkOption {
    #   type = types.str;
    #   description = "Path to the env file to use";
    #   default = "${config.services.rzw.userDir}/rzw.env";
    # };
    # adminPasswordHash = mkOption {
    #   type = types.str;
    #   description = ''Hash of the admin password. Get it with `php -r "echo password_hash('the_password_you_want', PASSWORD_DEFAULT);"`'';
    # };
  };

  config = mkIf cfg.enable
  /* let
    envFile = pkgs.writeText cfg.envFile ''
      DB_PATH="${cfg.sqliteFile}"
      ADMIN_PASSWD="${cfg.adminPasswordHash}"
    '';
  in */ {
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
      phpEnv."PATH" = lib.makeBinPath [ pkgs.php ];
    };
    services.nginx.virtualHosts."${cfg.domain}" = {
      forceSSL = true;
      enableACME = true;
      root = cfg.rootDir;
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
    };
  };
}
