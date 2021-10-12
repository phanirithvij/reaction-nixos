{ config, lib, ... }:
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
    };
    settings = {
      Nickname = "parpaing";
      BandwidthRate = 10 * 1024 * 1024; # 10 MB/s
      ContactInfo = "parpaing@tuta.io";
      ORPort = torPort;
    };
  };

  # Ou pas
  systemd.services.tor.wantedBy = lib.mkForce [];
}
