{ config, ... }:
{
  systemd.services.auto-poweroff = {
    enable = true;
    startAt = "*:0/5"; # every 5 minutes
    script = ''
      sshd_sessions="$(pgrep -u root sshd-session | wc -l)"
      flag_file=/tmp/no_remote_activity
      echo "sshd_sessions=$sshd_sessions"
      if test "$sshd_sessions" -eq 0
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
