{ lib, config, pkgs, ... }:
let 
  hosts = builtins.fromTOML (builtins.readFile ../common/hosts.toml);
in {
  options.ppom.musi-cache = {
    enable = lib.mkEnableOption "use musi as a Nix cache";
  };
  config = lib.mkIf config.ppom.musi-cache.enable {
    nix.settings = {
      # Put it after cache.nixos.org, which has faster bandwidth
      # So that we pull only custom packages from musi
      substituters = lib.mkAfter [ "http://${hosts.musi.address}:4977" ];
      trusted-public-keys = [ "key-name:2xd0yVuRgg0DXo4g+xnkYMkiEs8HvnnvU8c+yBhgAIs=" ];
    };
    # Upgrade after musi (which does upgrade at "04:40") so that it has already built shared packages
    system.autoUpgrade.dates = "05:10";
  };
}
