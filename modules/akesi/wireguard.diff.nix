{ lib, config, pkgs, ... }:

let
  wgPort = 123;
  genAddress = number: "10.10.0.${toString number}/32";
  externalInterface = "ens3";
in
{
  # enable NAT
  networking.nat = {
    enable = true;
    externalInterface = externalInterface;
    internalInterfaces = [ "wg0" ];
  };

  # Open WG port
  networking.firewall = {
    allowedTCPPorts = [ 53 wgPort ];
    allowedUDPPorts = [ 53 wgPort ];
  };

  # Enable routing
  boot.kernel.sysctl = {
    "net.ipv4.conf.all.forwarding" = lib.mkOverride 98 true;
    "net.ipv4.conf.default.forwarding" = lib.mkOverride 98 true;
  };

  services.dnsmasq = {
    enable = true;
    extraConfig = ''
      interface=wg0
    '';
  };

  networking.wg-quick.interfaces = {
    wg0 = {
      # Determines the IP address and subnet of the server's end of the tunnel interface.
      address = [ (genAddress 1) ];

      listenPort = wgPort;

      # This allows the wireguard server to route your traffic to the internet and hence be like a VPN
      postUp = ''
        ${pkgs.iptables}/bin/iptables -A FORWARD -i wg0 -j ACCEPT
        ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s ${genAddress 1} -o ${externalInterface} -j MASQUERADE
      '';

      # Undo the above
      preDown = ''
        ${pkgs.iptables}/bin/iptables -D FORWARD -i wg0 -j ACCEPT
        ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -s ${genAddress 1} -o ${externalInterface} -j MASQUERADE
      '';

      privateKeyFile = "...";

      peers = [
        { # desktop
          publicKey = "...";
          allowedIPs = [ (genAddress 2) ];
        }
      ];
    };
  };
}
