{ lib, pkgs, config, ... }:
let
  directusPort = 8059;
  common = import ../common.nix {};
in {
  services.directus.servers = {
    "ecotheque" = {
      enable = true;
      settings = common.settings // {
        PORT = directusPort;
      };
      nginx = {
        enable = true;
        serverName = "edit.ppom.me";
        location = "/ecotheque";
      };
    };
  };

  users.users."directus-ecotheque".extraGroups = [ "postmaster" ];

  systemd.services."directus-ecotheque".serviceConfig.Environment = [
    "ADMIN_EMAIL=ppom@ecomail.fr"
    "ADMIN_PASSWORD=prout"
  ];
}
