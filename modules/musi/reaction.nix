{ lib, pkgs, config, ... }:
let
  journalctl = "${pkgs.systemd}/bin/journalctl";
  iptables = "${pkgs.iptables}/bin/iptables";
  iptablesBan = [ "echo" iptables "-w" "-A" "reaction" "1" "-s" "<ip>" "-j" "DROP" ];
  iptablesUnban = [ "echo" iptables "-w" "-D" "reaction" "1" "-s" "<ip>" "-j" "DROP" ];
  banFor = duration: {
    ban = {
      cmd = iptablesBan;
    };
    unban = {
      cmd = iptablesUnban;
      after = duration;
    };
  };
in {
  services.reaction = {
    enable = true;
    settings = {
      patterns = {
        ip = ''(([0-9]{1,3}\.){3}[0-9]{1,3})|([0-9a-fA-F:]{2,90})'';
      };
      streams = {

        ssh = {
          cmd = [ journalctl "-fu" "sshd.service" ];
          filters.failedlogin = {
            regex = [
              "authentication failure;.*rhost=<ip>"
              "Connection reset by authenticating user .* <ip>"
            ];
            retry = 3;
            retry-period = "6h";
            actions = banFor "48h";
          };
        };

        kernel = {
          cmd = [ journalctl "-f" "-k" ];
          filters.portscan = {
            regex = [ "refused connection: .*SRC=<ip>" ];
            retry = 4;
            retry-period = "1h";
            actions = banFor "${toString (30 * 24)}h";
          };
        };

        nginx = {
          cmd = [ "tail" "-f" "/var/log/nginx/access.log" ];
          filters.suspectRequests = {
            regex = [
              ''^<ip>.*"GET //*wp-login\.php''
              ''^<ip>.*"GET //*\.env ''
              ''^<ip>.*"GET //*[^/]*/\.env ''
              ''^<ip>.*"GET //*config\.json ''
              ''^<ip>.*"GET //*info\.php ''
            ];
            actions = banFor "${toString (30 * 24)}h";
          };
        };

        nextcloud = {
          cmd = [ journalctl "-fu" "phpfpm-nextcloud.service" ];
          filters.failedLogin = {
            regex = [
              ''"remoteAddr":"<ip>".*"message":"Login failed:''
              ''"remoteAddr":"<ip>".*"message":"Trusted domain error.''
            ];
            actions = banFor "${toString (30 * 24)}h";
          };
        };

        # TODO
        # maddy = {
        # };
        # maddy-restart = {
        # };
        # vaultwarden = {
        # };

      };
    };
  };

  users.users.reaction.extraGroups = [
    "systemd-journal"
    "nginx"
  ];

  security.doas.extraRules = [{
    users = [ "reaction" ];
    cmd = iptables;
    args = null; # all arguments accepted
    runAs = "root";
  }];

  systemd.services.reaction.serviceConfig = {
    ExecStartPre= [
      # "${iptablesCommand} -w -N reaction"
      # "${iptablesCommand} -w -A reaction -j ACCEPT"
      # "${iptablesCommand} -w -I reaction 1 -s 127.0.0.1 -j ACCEPT"
      # "${iptablesCommand} -w -I reaction 1 -s ::1 -j ACCEPT"
      # "${iptablesCommand} -w -I INPUT -p all -j reaction"
      # TODO replace manual with iptables commands
    ];
    ExecStopPost = [
      # "${iptablesCommand} -w -D INPUT -p all -j reaction"
      # "${iptablesCommand} -w -F reaction"
      # "${iptablesCommand} -w -X reaction"
    ];
  };
}
