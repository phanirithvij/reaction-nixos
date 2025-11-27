{ pkgs, ... }:
let
in
{
  networking.wg-quick.interfaces.nasin.autostart = false;
  environment.systemPackages = [ pkgs.transmission-remote-gtk ];
}
