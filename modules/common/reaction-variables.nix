{ pkgs, ...}:
rec {
  journalctl = "${pkgs.systemd}/bin/journalctl";
  systemctl = "${pkgs.systemd}/bin/systemctl";
  iptables = "${pkgs.iptables}/bin/iptables";
  iptablesBan = [ iptables "-w" "-A" "reaction" "-s" "<ip>" "-j" "reaction-log-refuse" ];
  iptablesUnban = [ iptables "-w" "-D" "reaction" "-s" "<ip>" "-j" "reaction-log-refuse" ];
  banFor = duration: {
    ban = {
      cmd = iptablesBan;
    };
    unban = {
      cmd = iptablesUnban;
      after = duration;
    };
  };
}
