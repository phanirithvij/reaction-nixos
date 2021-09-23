{ config, pkgs, ... }:
{
  imports = [
    ./modules/akesi/configuration.nix
  ];
}
