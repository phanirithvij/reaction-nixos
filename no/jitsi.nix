{ config, pkgs, ... }:
let
  jitsiDomain = "chat.ppom.me";
  localAddress = "192.168.1.2";
  publicAddress = "88.160.19.71";
in
{
  # Open ports
  networking.firewall.allowedTCPPorts = [ 4443 10000 ];
  networking.firewall.allowedUDPPorts = [ 4443 10000 ];

  # Nginx config
  services.nginx.virtualHosts."${jitsiDomain}" = {
    forceSSL = true;
    enableACME = true;
  };

  # Jitsi meet config
  services.jitsi-meet = {
    enable = true;
    hostName = "chat.ppom.me";
    nginx.enable = true;
  };
  services.jitsi-videobridge = {
    enable = true;
    openFirewall = true;
    nat = {
      localAddress = localAddress;
      publicAddress = publicAddress;
    };
  };
}
