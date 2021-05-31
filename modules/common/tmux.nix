{ lib, config, pkgs, ... }:
{
  imports = [ ./ppom.nix ];

  config = {
    programs.tmux = {
      enable = true;
      clock24 = true;
      customPaneNavigationAndResize = true;
      historyLimit = 20000;
      keyMode = "vi";
      resizeAmount = 5;
      terminal = "screen-256color";
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

        set -g detach-on-destroy off # since tmux 3.2. Love it.
        '' else ''
        ''}
      '';
    };
  };
}
