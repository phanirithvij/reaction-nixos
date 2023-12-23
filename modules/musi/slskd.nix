{ lib, config, pkgs, ... }:
let
  var = import ../common/reaction-variables.nix { inherit pkgs; };
  # unstable = import <nixos-unstable> {};
in {
  services.slskd = {
    enable = true;
    # package = unstable.slskd;
    rotateLogs = true;
    openFirewall = true;
    environmentFile = "/var/secrets/slskd";
    nginx = {
      enable = true;
      domainName = "ppom.me";
      contextPath = "/slskd";
    };
    settings = {
      soulseek = {
        username = "pomme";
        listen_port = 2332;
        diagnostic_level = "Warning";
      };
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

  services.reaction.settings.streams.nginx.filters."slskd-failedLogin" = {
    regex = [
      ''^<ip> .* "POST /slskd/api/v0/session HTTP/..." 401 [0-9]+ .https://ppom.me''
      ''^<ip> .* "POST /kiosque/api/v0/session HTTP/..." 401 [0-9]+ .https://babos.land''
    ];
    retry = 3;
    retryperiod = "1h";
    actions = var.banFor "6h";
  };
}
