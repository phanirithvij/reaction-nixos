{ lib, config, pkgs, ... }:
let
  python = pkgs.python310.withPackages (ps: with ps; [
    requests
    feedgen
    beautifulsoup4
    pytz
  ]);
in {
  systemd.tmpfiles.rules = [
    "d /var/cache/rssify 0755 rssify rssify - -"
  ];

  users.users.rssify = {
    isSystemUser = true;
    group = "rssify";
  };
  users.groups.rssify = {};

  systemd.services.rssify = {
    enable = true;
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      User = "rssify";
      UMask = "022";
      ExecStartPre = pkgs.writeShellScript "rssify-pre.sh" ''
        set -e
        rm -f ./config.ini
        ln -s ${./config.ini} ./config.ini
      '';
      ExecStart = "${python}/bin/python ${./rssify.py}";
      WorkingDirectory = "/var/cache/rssify";
    };
    startAt = "daily";
  };

  services.nginx.virtualHosts."ppom.me".locations."/rssify" = {
    root = "/var/cache/";
    extraConfig = ''
      fancyindex on;
      fancyindex_exact_size off;
    '';
  };
}
