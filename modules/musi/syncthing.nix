{
  lib,
  pkgs,
  config,
  ...
}:
let
  relayPort = 22067;
  statusPort = 22070;
  musiLocalAddress = "192.168.1.35";
in
{
  services.syncthing = {
    relay = {
      enable = true;
      pools = [ "" ]; # stay private
      port = relayPort;
      listenAddress = musiLocalAddress;
      statusListenAddress = musiLocalAddress;
      statusPort = statusPort;
    };
  };
  networking.firewall.allowedTCPPorts = [
    relayPort
    statusPort
  ];
}
