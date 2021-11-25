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

  nix = {
    # FIXME `nix search` doesn't work
    extraOptions = ''experimental-features = nix-command'';

    # FIXME update to daemonIOSchedClass daemonIOSchedPriority
    # daemonIONiceLevel = 7;
    # FIXME update to daemonCPUSchedPolicy
    # daemonNiceLevel =   10;
  };

  programs.thefuck = {
    enable = true;
    alias = "f";
  };
}
