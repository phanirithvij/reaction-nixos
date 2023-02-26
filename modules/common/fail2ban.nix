{ lib, config, pkgs, ... }:
{
  options.ppom.fail2ban = {
    enable = lib.mkEnableOption "enable fail2ban";

    enableManual = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "enable a jail to manually ban ips or ip ranges";
    };

    enableSSHJail = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "enable SSH jail";
    };

    enableWPLogin = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "enable jail for bots hiting wp-login.conf";
    };
  };

  config = let
    cfg = config.ppom.fail2ban;

    wpLoginFilterFile = pkgs.writeText "wploginfilter.conf" ''
      [INCLUDES]
      before = common.conf

      [Definition]
      failregex = ^<ADDR>.*"GET //*wp-login\.php.*
                  ^<ADDR>.*"GET //*\.env .*
                  ^<ADDR>.*"GET //*[^/]*/\.env .*
                  ^<ADDR>.*"GET //*config\.json .*
                  ^<ADDR>.*"GET //*info\.php .*
      ignoreregex =
      datepattern = \[%%d/%%b/%%Y:%%H:%%M:%%S %%z\]
    '';
  in lib.mkIf cfg.enable {
    services.fail2ban = {
      enable = true;
      bantime-increment = {
        enable = true;
        maxtime = "48h";
      };
      jails.sshd = lib.mkIf cfg.enableSSHJail ''
        enabled = true
        port = 22
        mode = aggressive
        maxretry = 5
        findtime = 1200
        bantime = 4800
      '';

      jails.wplogin = lib.mkIf cfg.enableWPLogin ''
        enabled = true
        port = 80,443
        filter = wplogin
        maxretry = 1
        findtime = 3600
        bantime = ${toString (3600 * 24 * 30)}
        backend = polling
        logpath = /var/log/nginx/access.log
      '';

      jails.manual = lib.mkIf cfg.enableManual ''
        enabled = true
        action = iptables-allports
        # Any filter is ok
        filter = qmail
        maxretry = 9999
        findtime = 1
        bantime = ${toString (3600 * 24 * 365 * 5)}
        logpath = /dev/null
      '';
    };

    environment.etc."fail2ban/filter.d/wplogin.conf".source = lib.mkIf cfg.enableWPLogin wpLoginFilterFile;

    systemd.services.fail2ban.restartTriggers = [ wpLoginFilterFile ];
  };
}
