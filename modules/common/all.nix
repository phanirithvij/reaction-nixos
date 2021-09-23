{ config, pkgs, ... }:
{
  imports = [
    ./ppom.nix
    ./tmux.nix
    ./nvim.nix
    ./git.nix
    ./packages.nix
    ./environment.nix
  ];

  environment.homeBinInPath = true;

  programs.thefuck = {
    enable = true;
    alias = "f";
  };
}
