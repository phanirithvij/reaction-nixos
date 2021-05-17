{ lib, config, pkgs, ... }:
{
  imports = [
    ./ppom.nix
  ];

  config = {
    programs.tmux = {
      enable = true;
      clock24 = true;
      customPaneNavigationAndResize = true;
      historyLimit = 20000;
      keyMode = "vi";
      newSession = true;
      resizeAmount = 5;
      escapeTime = if config.ppom.isDesktop then 20 else 500;
      shortcut = if config.ppom.isDesktop then "q" else "b";

      extraConfig = ''
        bind ( copy-mode
        bind ù split-window -h
        bind S new-session
        bind -r "<" swap-window -d -t -1
	bind -r ">" swap-window -d -t +1

        ${if config.ppom.isDesktop then ''
        set -g status-style fg=#ffffff
        set -g status-style bg=#444444
        '' else ''
        ''}
      '';
    };
  };
}
