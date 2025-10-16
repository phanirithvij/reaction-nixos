{ config, pkgs, ... }:
{
  systemd.services.auto-poweroff = {
    enable = true;
    startAt = "*:0/5"; # every 5 minutes
    script = ''
      user_processes="$(${pkgs.procps}/bin/pgrep -G users | wc -l)"
      flag_file=/tmp/no_remote_activity
      echo "user_processes=$user_processes"
      if test "$user_processes" -eq 0
      then
        if test ! -e $flag_file
        then
          touch $flag_file
        else
          rm $flag_file
          ${config.systemd.package}/bin/systemctl poweroff
        fi
      else
        rm -f $flag_file
      fi
    '';
  };
}
