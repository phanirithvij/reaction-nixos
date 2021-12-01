{ lib, config, pkgs, ... }:

let
  wgPort = 123;
  externalInterface = "ens3";
  wireguardInterface = "wg0";
in
{
  # enable NAT
  networking.nat = {
    enable = true;
    externalInterface = externalInterface;
    internalInterfaces = [ wireguardInterface ];
  };

  # Open WG port
  networking.firewall = {
    allowedTCPPorts = [ 53 wgPort ];
    allowedUDPPorts = [ 53 wgPort ];
    trustedInterfaces = [ wireguardInterface ];
  };
  # Enable routing
  boot.kernel.sysctl = {
    "net.ipv4.conf.all.forwarding" = lib.mkOverride 98 true;
    "net.ipv4.conf.default.forwarding" = lib.mkOverride 98 true;
  };

  services.dnsmasq = {
    enable = true;
    extraConfig = ''
      interface=${wireguardInterface}
    '';
  };

  networking.wg-quick.interfaces = {
    "${wireguardInterface}" = {
      # Determines the IP address and subnet of the server's end of the tunnel interface.
      address = [ "10.0.0.1/24" ];

      listenPort = wgPort;

      # This allows the wireguard server to route your traffic to the internet and hence be like a VPN
      postUp = ''
        ${pkgs.iptables}/bin/iptables -A FORWARD -i ${wireguardInterface} -j ACCEPT
        ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s 10.0.0.0/16 -o ${externalInterface} -j MASQUERADE
      '';

      # Undo the above
      preDown = ''
        ${pkgs.iptables}/bin/iptables -D FORWARD -i ${wireguardInterface} -j ACCEPT
        ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -s 10.0.0.0/16 -o ${externalInterface} -j MASQUERADE
      '';

      privateKeyFile = "/var/secrets/wireguard/privatekey";

      peers = [
        { # sona
          publicKey = "UYjsvFMCc+yRBPxX4rHiuRx1jQd1WntClaAueNXNmh4=";
          allowedIPs = [ "10.0.0.2/32" ];
        }
        { # ilo
          publicKey = "Zz7tZ6UlbiCokqMI5BFTBiqn48taHL633ruWR6wi5GY=";
          allowedIPs = [ "10.0.0.3/32" ];
        }
      ];
    };
  };
}
