{ lib, pkgs, config, ... }:
let
  var = import ../common/reaction-variables.nix { inherit pkgs; };
in {
  services.photoprism = {
    enable = true;
    originalsPath = "/data/nextcloud/data/ppom/files/Photos";
    passwordFile = "/var/secrets/photoprism/admin";
    settings = {
      PHOTOPRISM_SITE_URL = "https://ppom.me/prism";
      PHOTOPRISM_DISABLE_TLS = "true";
    };
  };
  systemd.services.photoprism.serviceConfig.DynamicUser = lib.mkForce false;

  users.users.photoprism = {
    isSystemUser = true;
    group = "photoprism";
    extraGroups = [ "nextcloud" ];
  };
  users.groups.photoprism = {};

  services.nginx.virtualHosts."ppom.me".locations."/prism" = {
    proxyPass = "http://localhost:2342";
    proxyWebsockets = true;
  };

  # FIXME
  services.reaction.settings.streams.nginx.filters.photoprism = {
    regex = [
      ''^<ip> .* "POST /prism/api/v./session HTTP/..." 401 [0-9]+ .https://ppom.me''
    ];
    retry = 4;
    retryperiod = "1h";
    actions = var.banFor "${toString (30 * 24)}h";
  };
}
