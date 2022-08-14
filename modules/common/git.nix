{ lib, config, pkgs, ... }:
{
  environment.etc."gitconfig".text = ''
    [user]
        name = Paco${lib.optionalString (!config.ppom.isDesktop) " on ${config.networking.hostName}"}
        email = paco@ecomail.io
    [core]
        # Default ssh's askpass is a pain
        askPass =
    [difftool]
        tool = vimdiff
        prompt = false
    [diff]
        tool = vimdiff
    [alias]
        d = diff
        dc = diff --cached
        dt = difftool
        s = status
        a = add -A
        cm = commit -m
    [credential]
        helper = cache --timeout=${builtins.toString (4 * 60 * 60)}
    [pull]
        rebase = false
    [commit]
        verbose = true
  '';
}
