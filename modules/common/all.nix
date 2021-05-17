{ config, pkgs, ... }:
{
  imports = [
    ./ppom.nix
    ./tmux.nix
    ./nvim.nix
  ];
}
