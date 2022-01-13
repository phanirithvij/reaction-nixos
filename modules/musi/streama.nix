{ lib, pkgs, ... }:
with lib;
let
  domainName = "video.ppom.me";
  localPort = "8001";
in {
  # Reverse proxy configuration
  services.nginx.enable = true;
  services.nginx.virtualHosts."${domainName}" = {
      forceSSL = true;
      enableACME = true;
      locations = {

        "/" = {
          proxyPass = "http://localhost:${localPort}";
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
          # Needs the subsFilter NGINX module
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

  # Docker service configuration
  virtualisation = {
    docker.enable = true;
    oci-containers.containers = {
      streama = {
        autoStart = true;
        # FIXME impure: built locally from project's Dockerfile
        image = "streama:1.10.4";
        ports = [ "${localPort}:8080" ];
        volumes = [
          "/data/streama/uploads:/data/uploads"
          "/data/streama/movies:/data/movies"
          "/data/streama/data:/app/streama"
        ];
      };
    };
  };
}
