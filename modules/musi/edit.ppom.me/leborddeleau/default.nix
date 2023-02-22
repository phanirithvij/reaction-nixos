{ lib, pkgs, config, ... }:
let
  directusPort = 8057;
  common = import ../common.nix {};
in {
  services.directus.servers = {
    "leborddeleau" = {
      enable = true;
      settings = {
        PORT = directusPort;
      } // common.mailSettings;
      nginx = {
        enable = true;
        serverName = "edit.ppom.me";
        location = "/leborddeleau";
      };
    };
  };

  users.users."directus-leborddeleau".extraGroups = [ "postmaster" ];
}
