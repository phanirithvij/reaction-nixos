{ config, pkgs, ... }:
{
  users.users.mpd.extraGroups = [ "media" ];
  services.mpd = {
    enable = true;
    startWhenNeeded = true;
  };
}
