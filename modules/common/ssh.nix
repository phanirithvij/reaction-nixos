{ lib, config, pkgs, ... }:
let
  cfg = config.ppom.ssh;
in {
  options.ppom.ssh = {
    enable = lib.mkEnableOption "enable sshd config";

    port = lib.mkOption {
      type = lib.types.int;
      description = "ssh port";
    };

    hardened = lib.mkEnableOption "phobic installation";
  };

  config = lib.mkIf cfg.enable {
    services.openssh = {
      enable = true;
      ports = [ cfg.port ];
      permitRootLogin = "no";
    } // lib.optionalAttrs cfg.hardened {
      passwordAuthentication = false;
      allowSFTP = false;
    };

    # Mosh extension
    programs.mosh.enable = true;

    networking.firewall.allowedTCPPorts = [ cfg.port ];
  };
}
