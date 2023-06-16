{ lib, config, pkgs, ... }:
{
  options.ppom.reaction = {
    enable = lib.mkEnableOption "enable reaction";

    enableSSHJail = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "enable SSH jail";
    };

    enableNginx = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "enable jail for bots hiting wp-login.conf";
    };

    enablePortScan = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "enable jail for bots hiting closed ports";
    };
  };

  config = let
    cfg = config.ppom.reaction;
    var = import ./reaction-variables.nix { inherit pkgs; };

    iptablesBanRange = ipRange: "+${var.iptables} -w -A reaction -s ${ipRange} -j reaction-log-refuse";
    bannedIpRanges = [
      "46.148.40.0/24"
      "176.111.174.0/24"
      "94.102.61.0/24"
    ];
  in lib.mkIf cfg.enable {
    services.reaction = {
      enable = true;
      runAsRoot = true;
      settings = {
        patterns = {
          ip = ''(([0-9]{1,3}\.){3}[0-9]{1,3})|([0-9a-fA-F:]{2,90})'';
        };
        streams = {

          ssh = lib.mkIf cfg.enableSSHJail {
            cmd = [ var.journalctl "-fu" "sshd.service" ];
            filters.failedlogin = {
              regex = [
                "authentication failure;.*rhost=<ip>"
                "Connection reset by authenticating user .* <ip>"
              ];
              retry = 3;
              retry-period = "6h";
              actions = var.banFor "48h";
            };
          };

          kernel = lib.mkIf cfg.enablePortScan {
            cmd = [ var.journalctl "-f" "-k" ];
            filters.portscan = {
              regex = [ "refused connection: .*SRC=<ip>" ];
              retry = 4;
              retry-period = "1h";
              actions = var.banFor "${toString (30 * 24)}h";
            };
          };

          nginx = lib.mkIf cfg.enableNginx {
            cmd = [ "tail" "-n0" "-f" "/var/log/nginx/access.log" ];
            filters.suspectRequests = {
              regex = [
                ''^<ip>.*"GET //*wp-login\.php''
                ''^<ip>.*"GET //*\.env ''
                ''^<ip>.*"GET //*[^/]*/\.env ''
                ''^<ip>.*"GET //*config\.json ''
                ''^<ip>.*"GET //*info\.php ''
              ];
              actions = var.banFor "${toString (30 * 24)}h";
            };
            # TODO make a filter for too much failed requests
            # regex = [ ''^<ip>.*"(GET|POST).*" (404|444|403|400) '' ];
            # retry = 40;
            # retry-period = "1m";
            # TODO make a filter for failed http basic auth
          };
        };
      };
    };

    systemd.services.reaction.serviceConfig = {
      ExecStartPre= [
        "+${var.iptables} -w -N reaction"
        "+${var.iptables} -w -N reaction-log-refuse"
        "+${var.iptables} -w -A reaction -s 127.0.0.1 -j RETURN"
        "+${var.iptables} -w -A reaction -s 192.168.0.0/24 -j RETURN"
        "+${var.iptables} -w -A reaction-log-refuse -j LOG --log-prefix 'reaction banned connection: ' --log-level 6"
        "+${var.iptables} -w -A reaction-log-refuse -j nixos-fw-refuse"
        "+${var.iptables} -w -I INPUT -p all -j reaction"
      ] ++ builtins.map iptablesBanRange bannedIpRanges;
      ExecStopPost = [
        "+${var.iptables} -w -D INPUT -p all -j reaction"
        "+${var.iptables} -w -F reaction"
        "+${var.iptables} -w -X reaction"
        "+${var.iptables} -w -F reaction-log-refuse"
        "+${var.iptables} -w -X reaction-log-refuse"
      ];
      TimeoutStopSec = "3 min";
    };
  };
}
