{ config, pkgs, ...}:
rec {
  journalctl = "${config.systemd.package}/bin/journalctl";
  systemctl = "${config.systemd.package}/bin/systemctl";

  ip4tables = "${config.networking.firewall.package}/bin/iptables";
  ip6tables = "${config.networking.firewall.package}/bin/ip6tables";

  iptablesBan   = cmd: [ cmd "-w" "-A" "reaction" "-s" "<ip>" "-j" "DROP" ];
  iptablesUnban = cmd: [ cmd "-w" "-D" "reaction" "-s" "<ip>" "-j" "DROP" ];

  banFor = duration: {
    ban4 = {
      cmd = iptablesBan ip4tables;
      ipv4only = true;
    };
    ban6 = {
      cmd = iptablesBan ip6tables;
      ipv6only = true;
    };

    unban4 = {
      cmd = iptablesUnban ip4tables;
      ipv4only = true;
      after = duration;
    };
    unban6 = {
      cmd = iptablesUnban ip6tables;
      ipv6only = true;
      after = duration;
    };
  };

  freeMsg = msg: [
    "${pkgs.curl}/bin/curl"
    "--fail"
    "--silent"
    "--show-error"
    "--variable" "USER@/var/secrets/mobileapi-user"
    "--variable" "PASS@/var/secrets/mobileapi-pass"
    "--variable" "MSG=${msg}"
    "--expand-url"
    "https://smsapi.free-mobile.fr/sendmsg?user={{USER:trim}}&pass={{PASS:trim}}&msg={{MSG:trim:url}}"
  ];
}
