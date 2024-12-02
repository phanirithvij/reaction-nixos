{ pkgs, ...}:
rec {
  journalctl = "${pkgs.systemd}/bin/journalctl";
  systemctl = "${pkgs.systemd}/bin/systemctl";
  iptables = "${pkgs.callPackage ../../pkgs/reaction {}}/bin/ip46tables";
  iptablesBan = [ iptables "-w" "-A" "reaction" "-s" "<ip>" "-j" "nixos-fw-refuse" ];
  iptablesUnban = [ iptables "-w" "-D" "reaction" "-s" "<ip>" "-j" "nixos-fw-refuse" ];
  banFor = duration: {
    ban = {
      cmd = iptablesBan;
    };
    unban = {
      cmd = iptablesUnban;
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
