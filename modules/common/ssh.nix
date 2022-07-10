{ lib, config, pkgs, ... }:
let
  cfg = config.ppom.ssh;
in {
  options.ppom = {
    ssh = {
      enable = lib.mkEnableOption "enable sshd config & fail2ban";

      port = lib.mkOption {
        type = lib.types.int;
        description = "ssh port";
      };

      hardened = lib.mkOption {
        type = lib.types.bool;
        description = "phobic installation";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.openssh = lib.recursiveUpdate {
      enable = true;
      ports = [ cfg.port ];
      permitRootLogin = "no";
    } (if cfg.hardened then {
      passwordAuthentication = false;
      allowSFTP = false;
    } else {});

    # Mosh extension (doesn't work: TODO)
    # programs.mosh.enable = true;

    networking.firewall.allowedTCPPorts = [ cfg.port ];

    services.fail2ban = {
      enable = true;
      # Stick with default banaction, banaction-allports
      jails.sshd = ''
        enabled = true
        port = ${builtins.toString cfg.port}
        mode = aggressive
        maxretry = 5
        findtime = 1200
        bantime = ${if cfg.hardened then "4800" else "2400"}
      '';
    };
  };
}
