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
}
