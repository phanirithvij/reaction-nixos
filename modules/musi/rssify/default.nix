{ lib, config, pkgs, ... }:
let
  python = pkgs.python310.withPackages (ps: with ps; [
    requests
    feedgen
    beautifulsoup4
    pytz
  ]);
  script = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/h43z/rssify/ebd6dd0b159dea971f210b671f9211fc8f9f0622/rssify.py";
    sha256 = "sha256-Essrvg+DDyVaDplSTl3s/1U0+ZdRLUZoI8RzCL4n3FY=";
  };
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
      ExecStartPre = pkgs.writeScript "rssify-pre.sh" ''
        #!${pkgs.runtimeShell}
        set -e
        rm -f ./config.ini
        ln -s ${./config.ini} ./config.ini
      '';
      ExecStart = "${python}/bin/python ${script}";
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
