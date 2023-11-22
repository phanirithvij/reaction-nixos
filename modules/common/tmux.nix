{ lib, config, pkgs, ... }:
{
  options.ppom.tmux = {
    enable = lib.mkEnableOption "enable tmux with ppom config";
    desktop = lib.mkEnableOption "on a desktop";
  };

  config = let
    cfg = config.ppom.tmux;
  in {
    programs.tmux = {
      enable = true;
      clock24 = true;
      customPaneNavigationAndResize = true;
      historyLimit = 20000;
      keyMode = "vi";
      newSession = true;
      resizeAmount = 5;
      terminal = "screen-256color";
      escapeTime = if cfg.desktop then 20 else 500;
      shortcut = if cfg.desktop then "q" else "b";

      extraConfig = ''
        set -s command-alias[1] n='new -A'

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
      '' + lib.optionalString cfg.desktop ''
        set -g status-style fg=#ffffff,bg=#460179

        # Switch to another sessions when the current one ends
        set -g detach-on-destroy off

        # Neovim said this
        set-option -sa terminal-overrides ',xterm-256color:RGB'
        set-option -g focus-events on

        # Wayland said this
        set -ga update-environment ",SWAYSOCK,WAYLAND_DISPLAY"

        # ssh-agent said this
        set -ga update-environment ",SSH_AUTH_SOCK,SSH_AGENT_PID"
      '';
    };
  };
}
