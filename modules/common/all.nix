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

  i18n.supportedLocales = [ "en_US.UTF-8/UTF-8" "fr_FR.UTF-8/UTF-8" ];

  environment.homeBinInPath = true;

  nix.daemonIONiceLevel = 7;
  nix.daemonNiceLevel =   10;

  programs.thefuck = {
    enable = true;
    alias = "f";
  };
}
