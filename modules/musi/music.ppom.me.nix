{ lib, pkgs, config, ... }:
let 
  fwlink = pkgs.callPackage ../../pkgs/fwlink {};
in {
  services.funkwhale = {
    enable = true;
    enableLocalTypesense = true;
    funkwhaleVersion = "1.4.0";
    domainName = "music.ppom.me";
    musicDir = "/data/funkwhale/music";
    mediaDir = "/data/funkwhale/data/media";
    autoScan = {
      enable = true;
      passwordFile = "/var/secrets/funkwhale/scanToken";
      startAt = "*-*-02/2 20:00"; # man 5 systemd.time: every 2 days at 20:00
    };
  };

  users.users.funkwhale-playlist-import = {
    isSystemUser = true;
    group = "funkwhale";
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
          mkdir -p ./secrets
          echo "$INSTANCE_URL" > ./secrets/instance_url
          echo "$TOKEN" > ./secrets/token
          for file in $(ls lists/* | grep -v '/paco-' | grep -v '/pomme-' | grep -v '/tan-' )
          do
            ${python}/bin/python import-from-txt.py "$file"
          done
      '';
      User = "funkwhale-playlist-import";
      StateDirectory = "funkwhale-playlist-import";
    };
    startAt = "*-*-02/2 21:00"; # man 5 systemd.time: every 2 days at 20:00
  };

  # FunkwhaleLink

  users.users.fwlink = {
    isSystemUser = true;
    group = "funkwhale";
  };

  services.postgresql.ensureUsers = [ {
    name = "fwlink";
  } ];
  systemd.services.postgresql.postStart = lib.mkAfter ''
    $PSQL funkwhale -tAc 'GRANT CONNECT ON DATABASE funkwhale TO "fwlink"'
    $PSQL funkwhale -tAc 'GRANT SELECT ON ALL TABLES IN SCHEMA public TO "fwlink"'
    $PSQL funkwhale -tAc 'GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO "fwlink"'
  '';
  systemd.services.funkwhale-music-link-pre = {
    serviceConfig = {
      User = "postgres";
      ExecStart = ''${config.services.postgresql.package}/bin/psql funkwhale -c "GRANT SELECT ON TABLE music_trackactor, music_upload, music_track, music_album, music_artist TO root"'';
    };
  };

  # systemd.tmpfiles.rules = [
  #   "d /data/music-export/ 755 fwlink funkwhale - -"
  # ];

  systemd.services.funkwhale-music-link = {
    requires = [ "funkwhale-music-link-pre.service" ];
    after = [ "funkwhale-music-link-pre.service" ];

    path = [ config.services.postgresql.package ];
    serviceConfig = {
      # User = "fwlink";
      ExecStartPre = [
        "${pkgs.coreutils}/bin/rm -rf /data/music-export/music"
        "${pkgs.coreutils}/bin/mkdir /data/music-export/music"
      ];
      ExecStart = "${fwlink}/bin/fwlink /data/music-export/music";
      ExecStartPost = [
        "${pkgs.curl}/bin/curl -s -w '%{http_code}' -X PUT https://ppom.me/slskd/api/v0/shares -H @/var/secrets/slskd_header"
      ];
      TimeoutStartSec = "20min";
    };
    startAt = "daily";
  };
}
