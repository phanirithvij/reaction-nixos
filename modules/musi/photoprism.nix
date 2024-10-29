{ lib, pkgs, config, ... }:
let
  var = import ../common/reaction-variables.nix { inherit pkgs; };
in {
  services.photoprism = {
    enable = true;
    originalsPath = "/data/photoprism/";
    passwordFile = "/var/secrets/photoprism/admin";
    settings = {
      PHOTOPRISM_SITE_URL = "https://ppom.me/memes";
      PHOTOPRISM_DISABLE_TLS = "true";
    };
  };
  systemd.services.photoprism.serviceConfig.DynamicUser = lib.mkForce false;

  users.users.photoprism = {
    isSystemUser = true;
    group = "photoprism";
    extraGroups = [ "syncthing" ];
  };
  users.groups.photoprism = {};

  systemd.tmpfiles.rules = [
    "d  /data/syncthing 0750 syncthing syncthing - -"
    "d  /data/photoprism 0750 photoprism photoprism - -"
    "L+ /data/photoprism/Memes - - - - /data/syncthing/Memes"
  ];

  services.nginx.virtualHosts."ppom.me".locations."/memes" = {
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

  services.syncthing = {
    enable = true;
    dataDir = "/data/syncthing";
    openDefaultPorts = true;
    overrideDevices = true;
    overrideFolders = false;
    settings = {
      gui = {
        theme = "black";
        user = "ppom";
        insecureSkipHostcheck = true;
      };
      devices.sona = {
        id = "2CSU3PG-KPZM3V2-VTRO5OP-CTO3V6Y-7HMJLTZ-FSM57PL-CRMI7DT-G3SJXAD";
        autoAcceptFolders = true;
      };
      devices.ilo = {
        id = "4CSZ25H-RZIBVL4-YIYYB7P-GEGMMAA-DXWQPR7-BFHS65F-CCJSRRE-CFKAVQ4";
      };
    };
  };

  systemd.services.syncthing.serviceConfig.UMask = "0057";

  services.nginx.virtualHosts."ppom.me".locations."/sync/" = {
    proxyPass = "http://localhost:8384/";
    proxyWebsockets = true;
  };
}
