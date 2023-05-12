{ config, lib, ... }:
let
  torPort = 22;
in
{
  networking.firewall.allowedTCPPorts = [ torPort ];

  services.tor = {
    enable = true;
    enableGeoIP = true;
    relay = {
      enable = true;
      role = "relay";
    };
    settings = {
      Nickname = "parpaing";
      BandwidthRate = 10 * 1024 * 1024; # 10 MB/s
      ContactInfo = "parpaing@tuta.io";
      ORPort = torPort;
    };
  };
}
