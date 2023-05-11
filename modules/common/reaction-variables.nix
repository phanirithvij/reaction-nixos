{ pkgs, ...}:
rec {
  journalctl = "${pkgs.systemd}/bin/journalctl";
  doas = "/run/wrappers/bin/doas";
  systemctl = "${pkgs.systemd}/bin/systemctl";
  iptables = "${pkgs.iptables}/bin/iptables";
  iptablesBan = [ doas iptables "-w" "-A" "reaction" "-s" "<ip>" "-j" "DROP" ];
  iptablesUnban = [ doas iptables "-w" "-D" "reaction" "-s" "<ip>" "-j" "DROP" ];
  banFor = duration: {
    ban = {
      cmd = iptablesBan;
    };
    unban = {
      cmd = iptablesUnban;
      after = duration;
    };
  };
  doasReaction = {
    cmd,
    users ? [ "reaction" ],
    args ? null,
    runAs ? "root",
    noPass ? true,
    noLog ? true,
    ...
  }: [ {
    inherit users cmd args runAs noPass noLog;
  } ];
}
