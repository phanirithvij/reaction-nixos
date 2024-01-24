{ lib, pkgs, config, ... }:
let
  directusPort = 8064;
  common = import ../common.nix {};
in {
  services.directus.servers = {
    "edit" = {
      enable = true;
      settings = common.settings // {
        PORT = directusPort;
        LOG_LEVEL = "debug";
      };
      nginx = {
        enable = true;
        serverName = "edit.ppom.me";
        location = "/edit";
      };
    };
  };
}
