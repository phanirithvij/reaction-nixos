{ lib, pkgs, config, ... }:
let
  directusPort = 8059;
  common = import ./common.nix {};
in {
  services.directus.servers = {
    "coco" = {
      enable = true;
      settings = common.settings // {
        PORT = directusPort;
        LOG_LEVEL = "info";
      };
      nginx = {
        enable = true;
        serverName = "edit.ppom.me";
        location = "/coco";
      };
    };
  };
}
