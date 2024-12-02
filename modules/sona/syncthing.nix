{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.syncthing ];
  networking.firewall = {
    allowedTCPPorts = [ 8384 22000 ];
    allowedUDPPorts = [ 21027 22000 ];
  };
}
