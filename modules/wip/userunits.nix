{ config, pkgs, ... }:

{
  systemd.user.services = {
    # nc = {
    #   enable = true;
    #   description = "a local nc";
    #   unitConfig = {
    #     Type = "simple";
    #   };
    #   serviceConfig = {
    #     ExecStart = with pkgs; ''${bash}/bin/bash -c "${netcat}/bin/nc -l 8000 >> /home/ao/prg/nc.out"'';
    #   };
    #   wantedBy = [ "multi-user.target" ];
    # };

    # TODO
    # nordvpnfr = {
    #   enable = true;
    #   description = "VPN service";
    #   serviceConfig = {
    #     RemainAfterExit = "yes";
    #     Type = "oneshot";
    #     ExecStart = "${pkgs.tmux}/bin/tmux -2 new-session -d -s weechat ${pkgs.weechat}/bin/weechat";
    #     ExecStop = "${pkgs.tmux}/bin/tmux kill-session -t weechat";
    #   };
    #   wantedBy = [ "default.target" ];
    # };

    # TODO
    # vpnutc = {
      # dns utc : 192.168.13.4
    #   enable = true;
    #   description = "VPN service";
    #   serviceConfig = {
    #     RemainAfterExit = "yes";
    #     Type = "oneshot";
    #     ExecStart = "${pkgs.tmux}/bin/tmux -2 new-session -d -s weechat ${pkgs.weechat}/bin/weechat";
    #     ExecStop = "${pkgs.tmux}/bin/tmux kill-session -t weechat";
    #   };
    #   wantedBy = [ "default.target" ];
    # };


    # weechat = {
    #   enable = true;
    #   description = "Autostart Weechat in a tmux session";
    #   serviceConfig = {
    #     RemainAfterExit = "yes";
    #     Type = "oneshot";
    #     ExecStart = "${pkgs.tmux}/bin/tmux -2 new-session -d -s weechat ${pkgs.weechat}/bin/weechat";
    #     ExecStop = "${pkgs.tmux}/bin/tmux kill-session -t weechat";
    #   };
    #   wantedBy = [ "default.target" ];
    # };

    # dunst = {
    #   enable = true;
    #   description = "Dunst notification daemon";
    #   serviceConfig = {
    #     Type = "dbus";
    #     BusName = "org.freedesktop.Notifications";
    #     ExecStart = "${pkgs.dunst}/bin/dunst";
    #   };
    #   partOf = [ "graphical-session.target" ];
    # };

    # numlockx = {
    #   enable = true;
    #   description = "Num Lock at startup";
    #   serviceConfig = {
    #     Type = "oneshot";
    #     ExecStart = "${pkgs.numlockx}/bin/numlockx on";
    #   };
    #   partOf = [ "graphical-session.target" ];
    # };

    # conky = {
    #   enable = true;
    #   description = "Conky bar";
    #   serviceConfig = {
    #     ExecStart = ''${pkgs.bash}/bin/bash -c '${pkgs.conky}/bin/conky | while read i; do ${pkgs.xorg.xsetroot}/bin/xsetroot -name "$i"; done' '';
    #   };
    #   partOf = [ "graphical-session.target" ];
    # };

    # redshift = {
    #   enable = true;
    #   description = "Shift your screen to the red";
    #   serviceConfig = {
    #     ExecStart = ''${pkgs.redshift}/bin/redshift -l 48:2'';
    #   };
    #   partOf = [ "graphical-session.target" ];
    # };

  };
}

