{ config, pkgs, ... }:
{
  systemd.services.auto-poweroff = {
    enable = true;
    startAt = "*:0/5"; # every 5 minutes
    script = ''
      musi_processes="$(${pkgs.procps}/bin/pgrep -u musi | wc -l)"
      connected_users="$(who | wc -l)"
      flag_file=/tmp/no_remote_activity
      if test "$musi_processes" -eq 0 && test "$connected_users" -eq 0
      then
        if test ! -e $flag_file
        then
          touch $flag_file
        else
          rm $flag_file
          ${config.systemd.package}/bin/systemctl poweroff
        fi
      fi
    '';
  };
}
