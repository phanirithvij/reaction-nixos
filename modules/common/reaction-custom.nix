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

    enableGPTBot = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "enable jail for GPTBot";
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

    # iptablesBanRange = ipRange: "DROP";
    # bannedIpRanges = [
    #   "46.148.40.0/24"
    #   "176.111.174.0/24"
    #   "94.102.61.0/24"
    # ];
  in lib.mkIf cfg.enable {
    services.reaction = {
      enable = true;
      runAsRoot = true;
      settings = {
        patterns = {
          ip = {
            regex = ''(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(?:\.(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)){3}|(?:(?:[0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|(?:[0-9a-fA-F]{1,4}:){1,7}:|(?:[0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|(?:[0-9a-fA-F]{1,4}:){1,5}(?::[0-9a-fA-F]{1,4}){1,2}|(?:[0-9a-fA-F]{1,4}:){1,4}(?::[0-9a-fA-F]{1,4}){1,3}|(?:[0-9a-fA-F]{1,4}:){1,3}(?::[0-9a-fA-F]{1,4}){1,4}|(?:[0-9a-fA-F]{1,4}:){1,2}(?::[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:(?:(?::[0-9a-fA-F]{1,4}){1,6})|:(?:(?::[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(?::[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(?:ffff(?::0{1,4}){0,1}:){0,1}(?:(?:25[0-5]|(?:2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(?:25[0-5]|(?:2[0-4]|1{0,1}[0-9]){0,1}[0-9])|(?:[0-9a-fA-F]{1,4}:){1,4}:(?:(?:25[0-5]|(?:2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(?:25[0-5]|(?:2[0-4]|1{0,1}[0-9]){0,1}[0-9]))'';
            ignore = [
              "127.0.0.1"
              "::1"
            ];
          };
        };
        streams = {

          ssh = lib.mkIf cfg.enableSSHJail {
            cmd = [ var.journalctl "-fn0" "-u" "sshd.service" ];
            filters = {
              failedlogin = {
                regex = [
                  "authentication failure;.*rhost=<ip>(?: |$)"
                  "Failed password for .* from <ip> port"
                  "Invalid user .* from <ip> "
                  "Connection (?:reset|closed) by invalid user .* <ip> port"
                ];
                retry = 3;
                retryperiod = "6h";
                actions = var.banFor "48h";
              };
              connectionreset = {
                regex = [
                  "Connection (?:reset|closed) by(?: authenticating user .*)? <ip> port"
                  "Received disconnect from <ip> port .*[preauth]"
                  "Timeout before authentication for connection from <ip> to"
                ];
                retry = 4;
                retryperiod = "6h";
                actions = var.banFor "48h";
              };
            };
          };

          kernel = lib.mkIf cfg.enablePortScan {
            cmd = [ var.journalctl "-fn0" "-k" ];
            filters.portscan = {
              regex = [ "refused connection: .*SRC=<ip>" ];
              retry = 4;
              retryperiod = "1h";
              actions = var.banFor "${toString (30 * 24)}h";
            };
          };

          nginx = lib.mkIf (cfg.enableNginx || cfg.enableGPTBot) {
            cmd = [ "tail" "-n0" "-f" "/var/log/nginx/access.log" ];
            filters = {
              suspectRequests = lib.mkIf cfg.enableNginx {
                regex = [
                  # (?:[^/" ]*/)* is a "non-capturing group" regex that allow for subpath(s)
                  # example: /code/.env should be matched as well as /.env
                  #           ^^^^^
                  ''^<ip> .*"GET /(?:[^/" ]*/)*wp-login\.php''
                  ''^<ip> .*"GET /(?:[^/" ]*/)*wp-includes''
                  ''^<ip> .*"GET /(?:[^/" ]*/)*\.env ''
                  ''^<ip> .*"GET /(?:[^/" ]*/)*config\.json ''
                  ''^<ip> .*"GET /(?:[^/" ]*/)*info\.php ''
                  ''^<ip> .*"GET /(?:[^/" ]*/)*owa/auth/logon.aspx ''
                  ''^<ip> .*"GET /(?:[^/" ]*/)*auth.html ''
                  ''^<ip> .*"GET /(?:[^/" ]*/)*auth1.html ''
                  ''^<ip> .*"GET /(?:[^/" ]*/)*password.txt ''
                  ''^<ip> .*"GET /(?:[^/" ]*/)*passwords.txt ''
                  ''^<ip> .*"GET /(?:[^/" ]*/)*dns-query ''
                  ''^<ip> .*"GET /(?:[^/" ]*/)*\.git/ ''
                ];
                actions = var.banFor "${toString (30 * 24)}h";
              };
              gptbot = lib.mkIf cfg.enableGPTBot {
                regex = (builtins.map (bot: ''^<ip>.*"[^"]*${bot}[^"]*"$'') [
                  # Based on https://darkvisitors.com/agents
                  "AI2Bot"
                  "Amazonbot"
                  "Applebot"
                  "Applebot-Extended"
                  "Bytespider"
                  "CCBot"
                  "ChatGPT-User"
                  "ClaudeBot"
                  "Diffbot"
                  "DuckAssistBot"
                  "FacebookBot"
                  "GPTBot"
                  "Google-Extended"
                  "Kangaroo Bot"
                  "Meta-ExternalAgent"
                  "Meta-ExternalFetcher"
                  "OAI-SearchBot"
                  "PerplexityBot"
                  "Timpibot"
                  "Webzio-Extended"
                  "YouBot"
                  "omgili"
                ]);
                actions = var.banFor "${toString (30 * 24)}h";
              };

              # TODO make a filter for too much failed requests
              # regex = [ ''^<ip>.*"(GET|POST).*" (404|444|403|400) '' ];
              # retry = 40;
              # retryperiod = "1m";
              # TODO make a filter for failed http basic auth
            };
          };
        };
      };
    };

    systemd.services.reaction.serviceConfig = {
      ExecStartPre= [
        "+${var.iptables} -w -N reaction"
        "+${var.iptables} -w -A reaction -s 127.0.0.1 -j RETURN"
        "+${var.iptables} -w -A reaction -s 192.168.1.0/24 -j RETURN"
        "+${var.iptables} -w -I INPUT -p all -j reaction"
        "+${var.iptables} -w -I FORWARD -p all -j reaction"
      ]; # ++ builtins.map iptablesBanRange bannedIpRanges;
      ExecStopPost = [
        "+${var.iptables} -w -D INPUT -p all -j reaction"
        "+${var.iptables} -w -D FORWARD -p all -j reaction"
        "+${var.iptables} -w -F reaction"
        "+${var.iptables} -w -X reaction"
      ];
      TimeoutStopSec = "3 min";
    };
  };
}
