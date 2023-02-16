{ lib, pkgs, config, ... }:
{
  services.funkwhale = {
    enable = true;
    funkwhaleVersion = "1.2.9";
    domainName = "music.ppom.me";
    musicDir = "/data/funkwhale/music";
    mediaDir = "/data/funkwhale/data/media";
    autoScan = {
      enable = true;
      passwordFile = "/var/secrets/funkwhale/scanToken";
      startAt = "*-*-02/2 20:00"; # man 5 systemd.time: every 2 days at 20:00
    };
  };

  systemd.services.funkwhale-playlist-import = {
    serviceConfig = {
      Environment = [
        "INSTANCE_URL=https://${config.services.funkwhale.domainName}"
      ];
      EnvironmentFile = "/var/secrets/funkwhale/playlistImportToken";
      ExecStart = let
        python = pkgs.python3.withPackages (ps: with ps; [ requests rapidfuzz ]);
      in pkgs.writeScript "funkwhale-playlist-import" ''
        #!${pkgs.runtimeShell}
          set -e
          cd /var/lib/funkwhale-playlist-import
          [ -e ./funkwhale-playlist-import ] || ${pkgs.git}/bin/git clone https://framagit.org/ppom/funkwhale-playlist-import funkwhale-playlist-import
          cd ./funkwhale-playlist-import
          ${pkgs.git}/bin/git pull
          if [ ! -e ./secrets ]
          then
          mkdir ./secrets
          echo "$INSTANCE_URL" > ./secrets/instance_url
          echo "$TOKEN" > ./secrets/token
          fi
          for file in $(ls lists/* | grep -v '/paco-' | grep -v '/pomme-' | grep -v '/tan-' )
          do
            ${python}/bin/python import-from-txt.py "$file"
          done
      '';
      DynamicUser = true;
      StateDirectory = "funkwhale-playlist-import";
    };
    startAt = "*-*-02/2 21:00"; # man 5 systemd.time: every 2 days at 20:00
  };
}
