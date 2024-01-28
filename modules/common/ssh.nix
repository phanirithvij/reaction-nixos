{ lib, config, pkgs, ... }:
let
  cfg = config.ppom.ssh;
in {
  options.ppom.ssh = {
    enable = lib.mkEnableOption "enable sshd config";

    port = lib.mkOption {
      type = with lib.types; coercedTo int lib.singleton (listOf int);
      description = "ssh port";
    };

    hardened = lib.mkEnableOption "phobic installation";
  };

  config = lib.mkIf cfg.enable {
    services.openssh = {
      enable = true;
      ports = cfg.port;
      settings = {
        PermitRootLogin = "no";
      } // lib.optionalAttrs cfg.hardened {
        PasswordAuthentication = false;
      };
    } // lib.optionalAttrs cfg.hardened {
      allowSFTP = lib.mkDefault false;
    };

    programs.mosh.enable = true;
    environment.variables.MOSH_SERVER_NETWORK_TMOUT = builtins.toString (60*60*4);

    networking.firewall.allowedTCPPorts = cfg.port;
  };
}
