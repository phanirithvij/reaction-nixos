{ config, pkgs, ...}:
rec {
  journalctl = "${config.systemd.package}/bin/journalctl";
  systemctl = "${config.systemd.package}/bin/systemctl";

  ip4tables = "${config.networking.firewall.package}/bin/iptables";
  ip6tables = "${config.networking.firewall.package}/bin/ip6tables";

  ipset = "${pkgs.ipset}/bin/ipset";

  iptablesBan   = set: [ ipset "-exist" "add" set "<ip>" ];
  iptablesUnban = set: [ ipset "-exist" "del" set "<ip>" ];

  banFor = duration: {
    ban4 = {
      cmd = iptablesBan "reaction-4";
      ipv4only = true;
    };
    ban6 = {
      cmd = iptablesBan "reaction-6";
      ipv6only = true;
    };

    unban4 = {
      cmd = iptablesUnban "reaction-4";
      ipv4only = true;
      after = duration;
    };
    unban6 = {
      cmd = iptablesUnban "reaction-6";
      ipv6only = true;
      after = duration;
    };
  };

  mailMe = msg: cfg: {
    cmd = [
      "${pkgs.curl}/bin/curl"
      "--ssl-reqd"
      "--fail"
      "--silent"
      "--show-error"
      "--mail-from" cfg.fromMail
      "--mail-rcpt" cfg.destinationMail
      "--variable" "PASS@${cfg.mailAccountPasswordFile}"
      "--expand-user" "${cfg.mailAccount}:{{PASS:trim}}"
      "--header" "from: reaction <${cfg.fromMail}>"
      "--header" "to: ${cfg.destinationMail}"
      "--header" "subject: ${msg}"
      "--form" "=(;type=multipart/mixed"
      "--form" "=${msg};type=text/plain"
      "--form" "=)"
      "--url" "smtps://${cfg.mailServer}:465"
    ];
    oneshot = true;
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
