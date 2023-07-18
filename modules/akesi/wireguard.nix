{ lib, config, pkgs, ... }:
{
  environment.systemPackages = [ pkgs.wireguard-tools ];
  networking.firewall.allowedUDPPorts = [ 8095 ];

  # networking.wg-quick.interfaces.wg0 = {
  #   address = [ "10.0.0.1/24" ];
  #   listenPort = 8095;
  #   privateKeyFile = "/var/secrets/wg0";
  #   peers = [
  #     # musi
  #     {
  #       publicKey = "xN+0miJ1+iSvhEgYcymMJsZjduRuPYsZqbHnW8YBUTE=";
  #       allowedIPs = [ "10.0.0.0/24" ];
  #       persistentKeepalive = 25;
  #     }
  #   ];
  # };

  # fileSystems."/musi" = {
  #   device = "10.0.0.2:/data/user-uploads/akesi";
  #   options = [
  #     # Lazy mounting
  #     "x-systemd.automount" "noauto"
  #     # v3
  #     "nfsvers=3"
  #   ];
  # };
}
