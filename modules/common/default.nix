{ config, lib, ... }:
{
  imports = [
    ./directus
    ./funkwhale
    ./git.nix
    ./misc.nix
    ./monit.nix
    ./nasin.nix
    ./nvim.nix
    ./packages.nix
    ./reaction.nix
    ./reaction-custom.nix
    ./remote-build.nix
    ./ssh.nix
    ./tmux.nix
    ./user.nix
  ];

  options.ppom.enable = lib.mkEnableOption "enable default ppom environment";

  config = lib.mkIf config.ppom.enable {
    ppom.misc.enable = true;
    ppom.packages.enable = true;
    ppom.tmux.enable = true;
    ppom.nvim.enable = true;
    ppom.git.enable = true;
    ppom.user.enable = true;
    # server-side
    # ppom.reaction.enable = true;
    # ppom.ssh.enable = true;
  };
}
