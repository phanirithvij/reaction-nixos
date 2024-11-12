{ config, lib, pkgs, ... }:
let
  hostName = config.networking.hostName;
  hosts = builtins.fromTOML (builtins.readFile ./hosts.toml);
  host = hosts.${hostName};

  isServer = host: builtins.hasAttr "endpoint" host;
  isTheServer = host: builtins.hasAttr "preferred" host;

  # Peers don't have themselves as peers
  # "Clients" only have server peers
  # "Servers" have all peers
  filtered = builtins.attrValues (lib.filterAttrs (name: conf: (name != hostName) && (isServer conf || isServer host)) hosts);

  nonServers = builtins.attrValues (lib.filterAttrs (name: conf: (!isServer conf)) hosts);

  peers = builtins.map (conf: lib.mkMerge [
    {
      publicKey = conf.publicKey;
      allowedIPs = [ "${conf.address}/32" ];
    }
    (lib.optionalAttrs (isServer conf) {
      endpoint = conf.endpoint;
    })
    (lib.optionalAttrs ((isServer conf) && (!isServer host)) {
      persistentKeepalive = 30;
    })
    (lib.optionalAttrs ((isTheServer conf) && (!isServer host)) {
      # Clients connect to other peers via server routing
      allowedIPs = builtins.map (conf: "${conf.address}/32") nonServers;
    })
  ]) filtered;

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
