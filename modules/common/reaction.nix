{ lib, pkgs, config, ... }:
let
  settingsFormat = pkgs.formats.yaml {};
in {
  options.services.reaction = with lib; with types; {
    enable = mkEnableOption "enable reaction";

    package = mkOption {
      type = package;
      description = "The reaction package to use";
      default = pkgs.callPackage ../../pkgs/reaction {};
    };

    settings = mkOption {
      description = lib.mdDoc ''
        Configuration for reaction, see [configuration reference](https://framagit.org/ppom/reaction/-/blob/main/config/reaction.yml)
      '';
      default = {};
      type = submodule {
        freeformType = settingsFormat.type;
        options = {};
      };
    };

    runAsRoot = mkOption {
      type = bool;
      default = false;
      description = lib.mdDoc ''
        Whether to run reaction as root.
        Defaults to false, where an unprivileged reaction user is created.
        Be sure to give it sufficient permissions.
        Example config permitting `iptables` and `journalctl` use
        ```nix
        {
          users.users.reaction.extraGroups = [ "systemd-journal" ];

          security.doas.extraRules = [{
            users = [ "reaction" ];
            cmd = "$${pkgs.iptables}/bin/iptables";
            runAs = "root";
          }];
        }
        ```
      '';
    };
  };

  config = let
    cfg = config.services.reaction;
    configurationYaml = settingsFormat.generate "reaction.yml" cfg.settings;
  in {
    users = lib.mkIf (!cfg.runAsRoot) {
      users.reaction = {
        isSystemUser = true;
        group = "reaction";
      };
      groups.reaction = {};
    };

    systemd.services.reaction = {
      enable = true;
      description = "Daemon to ban hosts that cause multiple authentication errors";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        User = lib.mkIf (!cfg.runAsRoot) "reaction";
        ExecStart = ''${cfg.package}/bin/reaction -c ${configurationYaml}'';
        StateDirectory = "reaction";
        RuntimeDirectory = "reaction";
        WorkingDirectory = "/var/lib/reaction";
      };
    };

    environment.systemPackages = [ cfg.package ];
  };
}
