{ lib, pkgs, config, ... }:
let
  directusPort = 8062;
  common = import ../common.nix {};
in {
  services.directus.servers = {
    "chatons" = {
      enable = true;
      settings = common.settings // {
        PORT = directusPort;
      };
      nginx = {
        enable = true;
        serverName = "edit.ppom.me";
        location = "/chatons";
      };
    };
  };

  users.users."directus-chatons".extraGroups = [ "postmaster" ];
}
