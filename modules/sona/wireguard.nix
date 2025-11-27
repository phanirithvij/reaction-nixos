{
  lib,
  config,
  pkgs,
  ...
}:

{
  networking.wg-quick.interfaces.wg0 = {
    address = [ "10.10.0.2/24" ];

    dns = [ "10.10.0.1" ];

    privateKeyFile = "/var/secrets/wireguard/privatekey";

    peers = [
      {
        # akesi
        publicKey = "D7GuVBDF77tp369G5Mcvo8MBmHOvUAEGN6Ii3XgqXnc=";
        allowedIPs = [ "0.0.0.0" ];
        persistentKeepalive = 25;
        endpoint = "akesi.ppom.me:123";
      }
    ];
  };

  systemd.services.wg-quick-wg0.wantedBy = lib.mkForce [ ];
}
