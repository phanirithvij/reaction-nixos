{ lib, pkgs, ... }:
with lib;
let
  domainName = "video.ppom.me";
  localPort = "8001";
  # user = "streama";
  downFolder = pkgs.writeTextDir "index.html" ''
    <!doctype html>
    <html lang='fr'>
    <head>
        <meta charset='utf-8'>
        <link rel='icon' type='image/png' href='ppom.png'>
        <title>Netflox reviendra</title>
        <style>
                body {
                        display: flex;
                        flex-direction: column;
                        align-items: center;
                        justify-content: space-evenly;
                        background-color: black;
                        padding: 0;
                        margin: 0;
                        width: 100vw;
                        height: 100vh;
                        overflow: hidden;
                }
                h1, p, a {
                        color: #999;
                }
                .bug {
                        position: absolute;
                        bottom: 2vh;
                        right: 2vw;
                        color: #555;
                        font-size: 3vh;
                }
        </style>
    </head>

    <body>
        <h1>
          Netflox fait dodo
        </h1>
        <p>
          Il y a une
          <a href="https://log4jmemes.com">
            grosse
          </a>
          faille de sécurité (appelée Log4Shell) qui touche de nombreux logiciels, dont le logiciel Streama, qui fait fonctionner Netflox.
        </p>
        <p>
          Le temps que la développeuse du logiciel règle le problème de son côté, puis que je fasse une mise à jour propre, et Netflox repartira !
        </p>
        <p>
          En attendant, déso :/
        </p>
        <p>
          Si tu veux récupérer une vidéo en particulier (ou m'encourager), contacte-moi ^^
        </p>
    </body>
    </html>
  '';
in {
  # Reverse proxy configuration
  services.nginx.enable = true;
  services.nginx.virtualHosts."${domainName}" = {
      forceSSL = true;
      enableACME = true;
      locations = {

        "/" = {
          root = downFolder;
          # proxyPass = "http://localhost:${localPort}";
          extraConfig = ''
            add_header X-Content-Type-Options    "nosniff"       always;
            add_header X-Frame-Options           "DENY"          always;
            add_header X-XSS-Protection          "1; mode=block" always;
            # add_header Strict-Transport-Security "max-age=31536000";
            add_header Access-Control-Allow-Origin "https://video.ppom.me";
          '';
        };

        "/sub" = {
          return = "301 /sub/";
        };

        "/sub/" = {
          # Needs the subsFilter NGINX module?
          root = "/data/streama/movies";
          extraConfig = ''
            # Remove the sub/ in the root dir
            rewrite ^/sub(/.*)$ $1 break;

            # Show the files
            fancyindex on;
            fancyindex_exact_size off;

            # Filter mkv/mp4/avi files
            subs_filter '<tr>.*<a href="[^"]*.(mp4|mkv|avi)".*</tr>' ' ' r;
          '';
        };
        "~ /sub/.*\\.(mp4|mkv|avi)" = {
          return = "403";
        };
      };
  };
  # User configuration
  # users.users."${user}" = {
      # isSystemUser = true;
  # };

  # Docker service configuration
  virtualisation = {
    docker.enable = true;
    oci-containers.containers = {
      # streama = {
      #   autoStart = true;
      #   image = "streama:1.10.3";
      #   # user = user;
      #   ports = [ "${localPort}:8080" ];
      #   volumes = [
      #     "/data/streama/uploads:/data/uploads"
      #     "/data/streama/movies:/data/movies"
      #     "/data/streama/data:/app/streama"
      #   ];
      # };
    };
  };
}
