{ config, pkgs, ... }:
{
  imports = [
    ./ppom.nix
    ./tmux.nix
    ./nvim.nix
    ./git.nix
    ./video-packages.nix
  ];


  environment.homeBinInPath = true;

  programs.thefuck = {
    enable = true;
    alias = "f";
  };
}
