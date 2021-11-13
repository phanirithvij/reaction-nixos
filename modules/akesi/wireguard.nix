{ lib, config, pkgs, ... }:

let
  wgPort = 123;
  genAddress = number: "10.10.0.${toString number}/32";
in
{
  # enable NAT
  networking.nat.enable = true;
  networking.nat.externalInterface = "ens3";
  networking.nat.internalInterfaces = [ "wg0" ];

  # Open WG port
  networking.firewall.allowedUDPPorts = [ wgPort ];


  # Enable routing
  boot.kernel.sysctl = {
    "net.ipv4.conf.all.forwarding" = lib.mkOverride 98 true;
    "net.ipv4.conf.default.forwarding" = lib.mkOverride 98 true;
  };


  networking.wireguard.interfaces = {
    wg0 = {
      # Determines the IP address and subnet of the server's end of the tunnel interface.
      ips = [ (genAddress 1) ];

      listenPort = wgPort;

      # This allows the wireguard server to route your traffic to the internet and hence be like a VPN
      # For this to work you have to set the dnsserver IP of your router (or dnsserver of choice) in your clients
      postSetup = ''
        ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s ${genAddress 0} -o eth0 -j MASQUERADE
      '';

      # This undoes the above command
      postShutdown = ''
        ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -s ${genAddress 0} -o eth0 -j MASQUERADE
      '';

      privateKeyFile = "/var/secrets/wireguard/privatekey";

      peers = [
        { # sona
          publicKey = "UYjsvFMCc+yRBPxX4rHiuRx1jQd1WntClaAueNXNmh4=";
          allowedIPs = [ (genAddress 2) ];
        }
      ];
    };
  }; 
}

