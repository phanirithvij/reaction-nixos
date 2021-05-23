{ config, pkgs, ... }:
{
  environment.etc."gitconfig".text = ''
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
        helper = cache --timeout=14400
    [pull]
        rebase = false
  '';
}
