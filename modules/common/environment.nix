{ lib, config, pkgs, ... }:
{
  environment.shellAliases = {
    n = "cd /etc/nixos/modules";
    ll = "ls -lh";
    la = "ls -a";
    lla = "ls -lha";
    dc = "cd -";
  } // (if config.ppom.isDesktop then {
  } else {
  });

  # environment = {
  #   variables = {
  #   };
  # };

  programs.xonsh.config = ''
    aliases['n'] = ['cd', '/etc/nixos/modules']
  '';

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
  '';

  programs.fish.interactiveShellInit = ''
    function nix-dir; echo (dirname (dirname (realpath (which $argv[1])))); end
    function nix-cd; cd (nix-dir $argv[1]); end
    function nix-pkgs; cd /nix/var/nix/profiles/per-user/root/channels/nixos; end
    function nix; command nix --offline $argv; end
  '';
}
