{ lib, pkgs, ... }:
let
  localPort = "4587";
in { 
  # Reverse proxy configuration
  services.nginx.virtualHosts."ppom.me" = {
    locations."/GHBot" = {
      proxyPass = "http://localhost:${localPort}";
    };
  };

  virtualisation.oci-containers.containers.ghbot = {
    autoStart = true;
    image = "ulfs/ghmm";
    ports = [ "${localPort}:8000" ];
    environment = {
      MATTERMOST_URL = "https://team.picasoft.net";
      LOG_LEVEL = "DEBUG";
    };
    cmd = [ "/usr/local/bin/ghmm-exe" ];
    environmentFiles = [ "/var/secrets/GHBot.env" ];
  };
}
