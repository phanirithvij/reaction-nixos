{
  lib,
  pkgs,
  config,
  ...
}:
{
  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    virtualHosts.default = {
      default = true;
      root = "/var/www/public/";
      locations = {
        "/" = {
          index = "index.php";
        };
        "~ \.php$" = {
          extraConfig = ''
            fastcgi_split_path_info ^(.+\.php)(/.+)$;
            fastcgi_pass unix:${config.services.phpfpm.pools.secu.socket};
            include ${pkgs.nginx}/conf/fastcgi_params;
            include ${pkgs.nginx}/conf/fastcgi.conf;
          '';
        };
      };
    };
  };
  services.phpfpm.pools.secu = {
    user = "nginx";
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
      "php_flag[display_errors]" = true;
    };
  };
}
