{ lib, config, pkgs, ... }:
let
in {
  services.slskd = {
    enable = true;
    enableLogrotate = true;
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

  # Allow ppom to edit downloads
  systemd.services.slskd.serviceConfig.UMask = "0002";
  users.users.ppom.extraGroups = [ "slskd" ];

  environment.systemPackages = with pkgs; [ beets ];
}
