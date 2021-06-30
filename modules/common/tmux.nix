{ lib, config, pkgs, ... }:
let
  shortcut = if config.ppom.isDesktop then "q" else "b";
in
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
      shortcut = shortcut;

      extraConfig = ''
        bind q copy-mode
        bind Q paste-buffer
        bind S new-session

        # Swap window left/right
        bind -r "<" swap-window -d -t -1
	bind -r ">" swap-window -d -t +1

        # New windows and panes in the same directory
        unbind '"'
        unbind %
        unbind c
        bind '"' split-window    -c "#{pane_current_path}"
        bind %   split-window -h -c "#{pane_current_path}"
        # ù is more accessible on AZERTY
        bind ù   split-window -h -c "#{pane_current_path}"
        bind c   new-window      -c "#{pane_current_path}"

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
