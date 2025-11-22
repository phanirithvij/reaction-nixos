{ lib, config, pkgs, ... }:
{
  options.ppom.reaction = {
    enable = lib.mkEnableOption "enable reaction";

    enableSSHJail = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "enable SSH jail";
    };

    enableSystemd = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "enable light systemd unit monitoring";
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
    var = import ./reaction-variables.nix { inherit config pkgs; };

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
            type = "ip";
            ipv6mask = 64;
            ignore = [
              "127.0.0.1"
              "::1"
            ];
            ignorecidr = [
              "2a01:e0a:b3a:1dd0::/64"
            ];
          };
          unit = lib.mkIf cfg.enableSystemd {
            regex = ''[a-zA-Z0-9\-_@]+\.(:?automount|mount|scope|service|slice|socket|path|target|timer)\b'';
          };
        };
        streams = {

          ssh = lib.mkIf cfg.enableSSHJail {
            cmd = [ var.journalctl "-fn0" "-o" "cat" "-u" "sshd.service" ];
            filters = {
              failedlogin = {
                regex = [
                  "authentication failure;.*rhost=<ip>(?: |$)"
                  "Failed password for .* from <ip> port"
                  "Invalid user .* from <ip> "
                  "Connection (?:reset|closed) by invalid user .* <ip> port"
                ];
                retry = 2;
                retryperiod = "6h";
                actions = var.banFor "48h";
              };
              connectionreset = {
                regex = [
                  "Connection (?:reset|closed) by(?: authenticating user .*)? <ip> port"
                  "Received disconnect from <ip> port .*[preauth]"
                  "Timeout before authentication for connection from <ip> to"
                ];
                retry = 2;
                retryperiod = "6h";
                actions = var.banFor "48h";
              };
            };
          };

          kernel = lib.mkIf cfg.enablePortScan {
            cmd = [ var.journalctl "-fn0" "-o" "cat" "-k" ];
            filters.portscan = {
              regex = [ "refused connection: .*SRC=<ip>" ];
              retry = 4;
              retryperiod = "2h";
              actions = var.banFor "30d";
            };
          };

          nginx = lib.mkIf (cfg.enableNginx || cfg.enableGPTBot) {
            cmd = [ "tail" "-n0" "-F" "/var/log/nginx/access.log" ];
            filters = {
              suspectRequests = lib.mkIf cfg.enableNginx {
                regex = [
                  # (?:[^/" ]*/)* is a "non-capturing group" regex that allow for subpath(s)
                  # example: /code/.env should be matched as well as /.env
                  #           ^^^^^
                  ''^<ip> .*"GET /.DS_Store ''
                  ''^<ip> .*"GET /.vscode/sftp.json ''
                  ''^<ip> .*"GET /?rest_route=/wp/v2/users/ ''
                  ''^<ip> .*"GET /_all_dbs ''
                  ''^<ip> .*"GET /debug/default/view?panel=config ''
                  ''^<ip> .*"GET /etc/passwd ''
                  ''^<ip> .*"GET /server-status ''
                  ''^<ip> .*"GET /telescope/requests ''
                  ''^<ip> .*"GET /v2/catalog ''
                  ''^<ip> .*"GET /(?:[^/" ]*/)*admin\.php''
                  ''^<ip> .*"GET /(?:[^/" ]*/)*bypass\.php''
                  ''^<ip> .*"GET /(?:[^/" ]*/)*classwithtostring\.php''
                  ''^<ip> .*"GET /(?:[^/" ]*/)*css\.php''
                  ''^<ip> .*"GET /(?:[^/" ]*/)*info\.php ''
                  ''^<ip> .*"GET /(?:[^/" ]*/)*install\.php ''
                  ''^<ip> .*"GET /(?:[^/" ]*/)*log\.php''
                  ''^<ip> .*"GET /(?:[^/" ]*/)*mail\.php''
                  ''^<ip> .*"GET /(?:[^/" ]*/)*microsoft.exchange.ediscovery.exporttool.application ''
                  ''^<ip> .*"GET /(?:[^/" ]*/)*moon\.php''
                  ''^<ip> .*"GET /(?:[^/" ]*/)*pom.properties ''
                  ''^<ip> .*"GET /(?:[^/" ]*/)*radio\.php''
                  ''^<ip> .*"GET /(?:[^/" ]*/)*simple\.php''
                  ''^<ip> .*"GET /(?:[^/" ]*/)*test\.php''
                  ''^<ip> .*"GET /(?:[^/" ]*/)*wp-admin''
                  ''^<ip> .*"GET /(?:[^/" ]*/)*wp-content''
                  ''^<ip> .*"GET /(?:[^/" ]*/)*wp-includes''
                  ''^<ip> .*"GET /(?:[^/" ]*/)*wp-login\.php''
                  ''^<ip> .*"GET /(?:[^/" ]*/)*wp-mail\.php''
                  ''^<ip> .*"GET /(?:[^/" ]*/)*xleet\.php''
                  ''^<ip> .*"GET /(?:[^/" ]*/)*xmlrpc\.php''
                  ''^<ip> .*"GET /(?:[^/" ]*/)*phpinfo ''
                  ''^<ip> .*"GET /(?:[^/" ]*/)*\.env(?:\.[^/" ]*) ''
                  ''^<ip> .*"GET /(?:[^/" ]*/)*\.git/''
                  ''^<ip> .*"GET /(?:[^/" ]*/)*config\.json ''
                  ''^<ip> .*"GET /(?:[^/" ]*/)*owa/auth/logon.aspx ''
                  ''^<ip> .*"GET /(?:[^/" ]*/)*auth.html ''
                  ''^<ip> .*"GET /(?:[^/" ]*/)*auth1.html ''
                  ''^<ip> .*"GET /(?:[^/" ]*/)*password.txt ''
                  ''^<ip> .*"GET /(?:[^/" ]*/)*passwords.txt ''
                  ''^<ip> .*"GET /(?:[^/" ]*/)*dns-query ''
                  ''^<ip> .*"POST /(?:[^/" ]*/)*/cgi-bin/''
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

          systemd = lib.mkIf cfg.enableSystemd {
            cmd = [ var.journalctl "-fn0" "-o" "cat" "-t" "systemd" ];
            filters = {
              unit = {
                regex = [
                  "^<unit>: Failed with result"
                ];
                # No more than one alert each 6h
                duplicate = "ignore";
                actions =  {
                  mail = var.mailMe
                    "${config.networking.hostName}: unit <unit> failed"
                    config.ppom.monit;
                  dummy = {
                    cmd = ["true"];
                    after = "6h";
                  };
                };
              };
            };
          };
        };
      };
    };

    systemd.services.reaction.serviceConfig = let
      ip46tables = command: [
        "${var.ip4tables} ${command}"
        "${var.ip6tables} ${command}"
      ];
    in {
      ExecStartPre = builtins.concatMap ip46tables [
        "-w -N reaction"
        "-w -I INPUT -p all -j reaction"
        "-w -I FORWARD -p all -j reaction"
      ];
      ExecStopPost = builtins.concatMap ip46tables [
        "-w -D INPUT -p all -j reaction"
        "-w -D FORWARD -p all -j reaction"
        "-w -F reaction"
        "-w -X reaction"
      ];
      TimeoutStopSec = "3 min";
    };

    systemd.services.reaction-chain = let 
      iptables = "${config.networking.firewall.package}/bin/iptables";
      message = chain: "reaction chain has been removed from ${chain} :o";
      curl = chain: lib.concatStringsSep " " (map (item: ''"${item}"'') (var.freeMsg (message chain)));
    in {
      enable = true;
      startAt = "*:0/10";
      unitConfig.Requisite = [ "reaction.service" ];
      script = ''
        if ! ${iptables} -L INPUT | grep -q reaction
        then
          ${iptables} -w -I INPUT -p all -j reaction
          echo ${message "INPUT"}
          ${curl "INPUT"}
        fi

        if ! ${iptables} -L FORWARD | grep -q reaction
        then
          ${iptables} -w -I FORWARD -p all -j reaction
          echo ${message "FORWARD"}
          ${curl "FORWARD"}
        fi
      '';
    };
  };
}
