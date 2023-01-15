{ config, lib, pkgs, ... }:
{
  imports = [
    ./git.nix
    ./misc.nix
    ./nvim.nix
    ./packages.nix
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
    # ppom.ssh.enable = true;
  };
}
