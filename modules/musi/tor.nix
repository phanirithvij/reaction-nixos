{ config, pkgs, ... }:
let
  torPort = 22;
in
{
  # Open ports
  networking.firewall.allowedTCPPorts = [ torPort ];

  # Vas-y je suis un fou
  services.tor = {
    enable = true;
    # enable = false;
    enableGeoIP = true;
    relay = {
      enable = true;
      role = "relay";
      port = torPort;
      nickname = "parpaing";
      bandwidthRate = 10 * 1024 * 1024; # 10 MB/s
      contactInfo = "parpaing@tuta.io";
    };
  };
}
