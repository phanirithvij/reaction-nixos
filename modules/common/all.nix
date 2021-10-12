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

  i18n.supportedLocales = [ "en_US.UTF-8" "fr_FR.UTF-8" ];

  environment.homeBinInPath = true;

  programs.thefuck = {
    enable = true;
    alias = "f";
  };
}
