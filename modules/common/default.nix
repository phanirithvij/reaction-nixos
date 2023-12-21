{ config, lib, pkgs, ... }:
{
  imports = [
    ./directus
    ./funkwhale
    ./git.nix
    ./misc.nix
    ./monit.nix
    ./nvim.nix
    ./packages.nix
    ./reaction.nix
    ./reaction-custom.nix
    ./rustdesk-server.nix
    ./ssh.nix
    ./tmux.nix
  ];

  options.ppom.enable = lib.mkEnableOption "enable default ppom environment";

  config = lib.mkIf config.ppom.enable {
    ppom.misc.enable = true;
    ppom.packages.enable = true;
    ppom.tmux.enable = true;
    ppom.nvim.enable = true;
    ppom.git.enable = true;
    # server-side
    # ppom.reaction.enable = true;
    # ppom.ssh.enable = true;
  };
}
