{
  lib,
  config,
  pkgs,
  ...
}:
let
  wifiInterfaceName = "wlp3s0";
  ethernetInterfaceName = "eno1";
  # passphrase = "du hast mich gefragt und ich habe nicht gesagt";
  passphrase = "du hast mich gefragt";
in
{
  # With help from these blogs:
  # - https://labs.quansight.org/blog/2020/07/nixos-rpi-wifi-router/
  # - https://www.linux.com/training-tutorials/create-secure-linux-based-wireless-access-point/
  # - https://techsansar.com/how-to/turn-linux-machine-wifi-access-point/

  # For now it doesn't work.
  # I'm using my host as a standard router.
  # I think it would be better to use the method of the third blog and to use NAT forwarding instead of simple routing.
  # It could work properly wherever I am and whathever network it is in, by using a local network

  # IP forwarding
  # boot.kernel.sysctl = {
  #   "net.ipv4.conf.all.forwarding" = lib.mkOverride 97 true;
  #   "net.ipv4.conf.default.forwarding" = lib.mkOverride 97 true;
  # };

  # Hardware level
  # hardware.enableRedistributableFirmware = true;
  # networking.wireless.enable = true;
  # # Bridge ethernet and wifi
  # networking.bridges.br0.interfaces = [ ethernetInterfaceName wifiInterfaceName ];

  # Disable networkmanager-related things
  # networking.networkmanager.unmanaged = [ wifiInterfaceName ];
  # systemd.services.wpa_supplicant.enable = false;

  # Wireless static IP address
  # networking.interfaces."${wifiInterfaceName}" = {
  #   ip4 = lib.mkOverride 0 [ ];
  #   ipv4.addresses = [{ address = "192.168.0.2"; prefixLength = 24; }];
  # };

  # FIXME Don't know why
  # networking.firewall.allowedUDPPorts = [53 67];

  # Haveged refills /dev/random when low
  # services.haveged.enable = true;

  # Access point daemon
  # services.hostapd = {
  #   enable = true;
  #   hwMode = "g";
  #   interface = wifiInterfaceName;
  #   ssid = "sona";
  #   wpa = true;
  #   wpaPassphrase = passphrase;
  #   # driver = "wilwifi";
  # };

  # DNS
  # services.dnsmasq = {
  #   enable = true;
  #   extraConfig = ''
  #     interface=${wifiInterfaceName}
  #     bind-interfaces
  #     dhcp-range=192.168.0.60,192.168.0.70,24h
  #   '';
  # };

  # DHCP
  # networking.dhcpd = {
  #   enable = true;
  #   allowInterfaces = [ wifiInterfaceName ];
  # };
}
