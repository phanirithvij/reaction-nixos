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

    enableGoogleImpersonator = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "enable jail for bots hiding behind google's User-Agent";
    };
  };

  config = let
    cfg = config.ppom.reaction;
    var = import ./reaction-variables.nix { inherit config pkgs; };

    replaceActions = { name, file, actions }: "${(pkgs.writeTextFile {
      inherit name;
      destination = "/${name}";
      # Horrible hack because reaction doesn't merge filters
      # So we manually insert an actions object in the jsonnet file
      text = builtins.replaceStrings
        ["'ACTIONS'"]
        [(builtins.readFile ((pkgs.formats.json {}).generate "ban.json" actions))]
        (builtins.readFile file);
    })}/${name}";
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
      settingsFiles = lib.optional cfg.enableGoogleImpersonator
        (replaceActions { name = "googlebot.jsonnet"; file = ./googlebot.jsonnet; actions = (var.banFor "30d"); })
        ++ lib.optional cfg.enableGPTBot
        (replaceActions { name = "ai-robots.jsonnet"; file = ./ai-robots.jsonnet; actions = (var.banFor "30d"); });
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
            regex = ''[a-zA-Z0-9\-_@]+\.(?:automount|mount|scope|service|slice|socket|path|target|timer)\b'';
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
            filters = let
                rootPaths = [
                  ''\.DS_Store''
                  ''\.vscode/sftp\.json''
                  ''\?rest_route=/wp/v2/users/''
                  ''_all_dbs''
                  ''containers/json''
                  ''\+CSCO(?:L|E)\+''
                  ''debug/default/view\?panel=config''
                  ''etc/passwd''
                  ''geoserver/web/''
                  ''graphql''
                  ''api/graphql''
                  ''llms\.txt''
                  ''server-status''
                  ''sftp-config\.json''
                  ''telescope/requests''
                  ''v2/catalog''
                ];
                relativePaths = [
                  ''\.env''
                  ''auth1?\.html''
                  ''config\.json''
                  ''dns-query''
                  ''microsoft\.exchange\.ediscovery\.exporttool\.application''
                  ''owa/auth/logon\.aspx''
                  ''passwords?\.txt''
                  ''phpinfo''
                  ''pom\.properties''
                ];
                relativePathsNoSpace = [
                  ''\.env\.''
                  ''\.git/''
                  ''wp''
                  ''meta\.json''
                ];
                phpPaths = [
                  "abcd"
                  "admin"
                  "bypass"
                  "classwithtostring"
                  "css"
                  "eval-stdin"
                  "info"
                  "install"
                  "log"
                  "mail"
                  "moon"
                  "phpunit"
                  "radio"
                  "simple"
                  "test"
                  "wp-login"
                  "wp-mail"
                  "xleet"
                  "xmlrpc"
                ];
              in {
              suspectRequests = lib.mkIf cfg.enableNginx {
                regex = [
                  # All absolute paths that end with space
                  # 
                  ''^<ip> .*"GET /(?:${lib.concatStringsSep "|" rootPaths}) ''
                  # (?:[^/" ]*/)* is a "non-capturing group" regex that allow for subpath(s)
                  # example: /code/.env should be matched as well as /.env
                  #           ^^^^^
                  ''^<ip> .*"GET /(?:[^/" ]*/)*(?:${lib.concatStringsSep "|" phpPaths})\.php''
                  ''^<ip> .*"GET /(?:[^/" ]*/)*(?:${lib.concatStringsSep "|" relativePaths}) ''
                  ''^<ip> .*"GET /(?:[^/" ]*/)*(?:${lib.concatStringsSep "|" relativePathsNoSpace})''
                  ''^<ip> .*"POST /(?:[^/" ]*/)*/cgi-bin/''
                ];
                actions = var.banFor "30d";
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

    environment.systemPackages = [ pkgs.ipset ];

    systemd.services.reaction.serviceConfig = let
    in {
      ExecStartPre = [
        "${var.ipset} create reaction-4 hash:net family inet hashsize 65536 maxelem 3000000 timeout 0"
        "${var.ipset} create reaction-6 hash:net family inet6 hashsize 65536 maxelem 3000000 timeout 0"
        "${var.ip4tables} -w -I INPUT   -m set --match-set reaction-4 src -j DROP"
        "${var.ip6tables} -w -I INPUT   -m set --match-set reaction-6 src -j DROP"
        "${var.ip4tables} -w -I FORWARD -m set --match-set reaction-4 src -j DROP"
        "${var.ip6tables} -w -I FORWARD -m set --match-set reaction-6 src -j DROP"
      ]
        ++ lib.optional cfg.enableGoogleImpersonator "${pkgs.curl}/bin/curl -o /var/lib/reaction/googlebot.json https://developers.google.com/search/apis/ipranges/googlebot.json"
        ++ lib.optional cfg.enableGPTBot "${pkgs.curl}/bin/curl -o /var/lib/reaction/ai-robots.json https://raw.githubusercontent.com/ai-robots-txt/ai.robots.txt/refs/heads/main/robots.json"
      ;
      ExecStopPost = [
        "${var.ip4tables} -w -D INPUT   -m set --match-set reaction-4 src -j DROP"
        "${var.ip6tables} -w -D INPUT   -m set --match-set reaction-6 src -j DROP"
        "${var.ip4tables} -w -D FORWARD -m set --match-set reaction-4 src -j DROP"
        "${var.ip6tables} -w -D FORWARD -m set --match-set reaction-6 src -j DROP"
        "${var.ipset} destroy reaction-4"
        "${var.ipset} destroy reaction-6"
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
