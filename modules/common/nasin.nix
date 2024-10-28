{ config, lib, pkgs, ... }:
let
  hostName = config.networking.hostName;
  hosts = builtins.fromTOML (builtins.readFile ./hosts.toml);
  host = hosts.${hostName};

  filtered = lib.filterAttrs (name: conf: name != hostName) hosts;
  peers = lib.mapAttrsToList (name: conf: {
    publicKey = conf.publicKey;
    allowedIPs = [ "${conf.address}/32" ];
  } // lib.optionalAttrs (builtins.hasAttr "endpoint" conf) {
    endpoint = conf.endpoint;
  }) filtered;

in lib.mkIf (builtins.hasAttr hostName hosts) {

  environment.systemPackages = [ pkgs.wireguard-tools ];

  networking = {
    firewall.allowedUDPPorts = [ host.listenPort ];

    wg-quick.interfaces.nasin = {
      address = [ "${host.address}/24" ];
      privateKeyFile = "/var/secrets/nasin.key";
      listenPort = host.listenPort;
      peers = peers;
    };
  };
}
