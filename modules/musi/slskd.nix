{ lib, config, pkgs, ... }:
let
  var = import ../common/reaction-variables.nix { inherit pkgs; };
  # unstable = import <nixos-unstable> {};
in {
  services.slskd = {
    enable = true;
    # package = unstable.slskd;
    openFirewall = true;
    environmentFile = "/var/secrets/slskd";
    domain = "ppom.me";
    nginx = {
      enableACME = true;
      forceSSL = true;
    };
    settings = {
      soulseek = {
        username = "pomme";
        listen_port = 2332;
        diagnostic_level = "Warning";
      };
      web = {
        url_base = "/slskd";
        authentication = {
          username = "ppom";
          # api_keys.local = {
          #   key = "6KAhjnXtk3rcgXO2DHHEWa8tEkCqsZ4Gijrbqy2T3yb";
          #   cidr = "127.0.0.1";
          # };
        };
      };
      shares.directories = [
        "[music]/data/music-export/music"
        "[movies]/data/streama/movies"
      ];
    };
  };

  # Allow ppom to edit downloads
  systemd.services.slskd.serviceConfig.UMask = "0002";
  users.users.ppom.extraGroups = [ "slskd" ];

  environment.systemPackages = with pkgs; [ beets id3v2 ];

  services.reaction.settings.streams.nginx.filters."slskd-failedLogin" = {
    regex = [
      ''^<ip> .* "POST /slskd/api/v0/session HTTP/..." 401 [0-9]+ .https://ppom.me''
      ''^<ip> .* "POST /kiosque/api/v0/session HTTP/..." 401 [0-9]+ .https://babos.land''
    ];
    retry = 3;
    retryperiod = "1h";
    actions = var.banFor "6h";
  };

  # Low prio startup
  systemd.services.slskd.wantedBy = lib.mkForce [ "multi-user3.target" ];
}
