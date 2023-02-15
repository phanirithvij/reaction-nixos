{ lib, config, pkgs, ... }:
{
  options.ppom.fail2ban = {
    enable = lib.mkEnableOption "enable fail2ban";

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
      failregex = ^<ADDR>.*"GET /wp-login.php.*
      ignoreregex =
      datepattern = \[%%d/%%b/%%Y:%%H:%%M:%%S %%z\]
    '';
  in lib.mkIf cfg.enable {
    services.fail2ban = {
      enable = true;
      # Stick with default banaction, banaction-allports
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
    };

    environment.etc."fail2ban/filter.d/wplogin.conf".source = lib.mkIf cfg.enableWPLogin wpLoginFilterFile;

    systemd.services.fail2ban.restartTriggers = [ wpLoginFilterFile ];
  };
}
