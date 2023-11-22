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

    # Not working, no ExecReloadPre
    # stopForFirewall = mkOption {
    #   type = bool;
    #   default = false;
    #   description = lib.mdDoc ''
    #     Whether to stop reaction when reloading the firewall
        
    #     The presence of a reaction chain in the INPUT table may cause the firewall
    #     reload to fail.
    #     One can alternatively cherry-pick the right iptables commands to execute before and after the firewall
    #     ```nix
    #     {
    #       systemd.services.firewall.serviceConfig = {
    #         ExecStopPre = [ "${pkgs.iptables}/bin/iptables -w -D INPUT -p all -j reaction" ];
    #         ExecStartPost = [ "${pkgs.iptables}/bin/iptables -w -I INPUT -p all -j reaction" ];
    #       };
    #     }
    #     ```
    #   '';
    # };

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
  in lib.mkIf cfg.enable {
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
      path = [ pkgs.iptables ];
      serviceConfig = {
        Type = "simple";
        User = lib.mkIf (!cfg.runAsRoot) "reaction";
        ExecStart = ''${cfg.package}/bin/reaction start -c ${configurationYaml}'';
        StateDirectory = "reaction";
        RuntimeDirectory = "reaction";
        WorkingDirectory = "/var/lib/reaction";
      };
    };

    environment.systemPackages = [ cfg.package ];
  };
}
