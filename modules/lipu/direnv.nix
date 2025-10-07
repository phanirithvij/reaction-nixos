# This snippet was found here: https://github.com/nix-community/nix-direnv

# It permits to autoload shell.nix files without the need to execute nix-shell,
# and saves this derivations to gcroots, so that output derivations are not garbage collected.
# Also 
# echo 'source /run/current-system/sw/share/nix-direnv/direnvrc' >> ~/.direnvrc

{ config, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    direnv # for use with nix-shell
    nix-direnv # for use with direnv
  ];
  # nix options for derivations to persist garbage collection
  nix.extraOptions = ''
    keep-outputs = true
    keep-derivations = true
  '';
  environment.pathsToLink = [
    "/share/nix-direnv"
  ];
}
