{ config, pkgs, ... }:
let
  torPort = 143;
in
{
  # Open ports
  networking.firewall.allowedTCPPorts = [ torPort ];

  # Vas-y je suis un fou
  services.tor = {
    enable = true;
    enableGeoIP = true;
    relay = {
      enable = true;
      role = "relay";
      port = torPort;
      nickname = "parpaing";
      bandwidthRate = 8 * 1024 * 1024; # 8 MB/s
      contactInfo = "parpaing@tuta.io";
    };
  };
}
