{ lib, pkgs, config, ... }:
let
  directusPort = 8064;
  common = import ./common.nix {};
in {
  services.directus.servers = {
    "edit.ppom.fr" = {
      enable = true;
      settings = common.settings // {
        PORT = directusPort;
        LOG_LEVEL = "info";
      };
      nginx = {
        enable = true;
        serverName = "edit.ppom.fr";
      };
    };
  };
}
