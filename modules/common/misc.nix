{ lib, config, pkgs, ... }:
{
  options.ppom.misc.enable = lib.mkEnableOption "enable ppom misc";

  config = lib.mkIf config.ppom.misc.enable {

    nix = {
      settings = {
        connect-timeout = 5;
        log-lines = 25;
        auto-optimise-store = true;
      };
      # FIXME update to daemonIOSchedClass daemonIOSchedPriority
      # daemonIONiceLevel = 7;
      # FIXME update to daemonCPUSchedPolicy
      # daemonNiceLevel =   10;
    };

    system.autoUpgrade.enable = lib.mkDefault true;
    system.autoUpgrade.allowReboot = lib.mkDefault false;

    environment.shellAliases = {
      n = "cd /etc/nixos/modules";
      ll = "ls -lh";
      la = "ls -a";
      lla = "ls -lha";
      dc = "cd -";
    };

    environment.homeBinInPath = true;

    environment.systemPackages = with pkgs; [
      atuin
    ];

    programs.bash.interactiveShellInit = ''
      # load fzf key-bindings
        [ -f ${pkgs.fzf}/share/fzf/key-bindings.bash ] && source ${pkgs.fzf}/share/fzf/key-bindings.bash
      # do not load completion because it breaks other completions
      # [ -f ${pkgs.fzf}/share/fzf/completion.bash ] && source ${pkgs.fzf}/share/fzf/completion.bash

      # custom functions
      function nix-dir()  { echo "$(dirname "$(dirname "$(realpath "$(which "$1")")")")"; }
      function nix-cd()   { cd "$(nix-dir "$1")"; }
      function nix-pkgs() { cd /nix/var/nix/profiles/per-user/root/channels/nixos; }
      function nix()      { command nix --offline "$@"; }

      source ${pkgs.bash-preexec}/share/bash/bash-preexec.sh
      eval "$(atuin init bash)"
    '';

    programs.fish.interactiveShellInit = ''
      function nix-dir; echo (dirname (dirname (realpath (which $argv[1])))); end
      function nix-cd; cd (nix-dir $argv[1]); end
      function nix-pkgs; cd /nix/var/nix/profiles/per-user/root/channels/nixos; end
      function nix; command nix --offline $argv; end

      atuin init fish | source
    '';
  };
}
