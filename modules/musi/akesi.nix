{ config, pkgs, ... }:
{
  environment.systemPackages = [ pkgs.wireguard-tools ];

  networking.wg-quick.interfaces.wg0 = {
    address = [ "10.0.0.2/24" ];
    privateKeyFile = "/var/secrets/wg0";
    peers = [
      # akesi
      {
        publicKey = "fFH+oRg+iU2tKzCksRvr+JYdAf3CAd8MgSwkY/2ctgE=";
        allowedIPs = [ "10.0.0.0/24" ];
        endpoint = "54.37.74.51:8095";
        persistentKeepalive = 25;
      }
    ];
  };

  services.nfs.server = {
    enable = true;
    exports = ''
      /data/user-uploads/akesi 10.0.0.1(rw,nohide,insecure,no_subtree_check)
    '';
  };

  networking.firewall.allowedUDPPorts = [ 4242 ];
  services.nebula.networks.kulupu = {
    enable = true;
    ca   = "/var/secrets/nebula/kulupu/ca.crt";
    cert = "/var/secrets/nebula/kulupu/musi.crt";
    key  = "/var/secrets/nebula/kulupu/musi.key";
    firewall = {
      outbound = [
        { host = "any"; port = "any"; proto = "icmp"; }
      ];
      inbound = [
        { host = "musi"; port = "2049"; proto = "any"; }
        { host = "any"; port = "any"; proto = "icmp"; }
      ];
    };
    isLighthouse = true;
    staticHostMap = { "192.168.100.1" = [ "54.37.74.51" ]; };
    settings = {};
  };
}
