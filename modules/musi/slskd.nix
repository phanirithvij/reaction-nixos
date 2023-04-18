{ lib, config, pkgs, ... }:
let
in {
  services.slskd = {
    enable = true;
    openFirewall = true;
    environmentFile = "/var/secrets/slskd";
    nginx = {
      enable = true;
      domainName = "ppom.me";
      contextPath = "/slskd";
    };
    settings = {
      soulseek.username = "pomme";
      web.authentication.username = "ppom";
      shares.directories = [
        "[music]/data/music-export/music"
        "[movies]/data/streama/movies"
      ];
    };
  };
}
