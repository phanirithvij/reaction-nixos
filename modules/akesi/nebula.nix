{ lib, config, pkgs, ... }:
{
  networking.firewall.allowedUDPPorts = [ 4242 ];
  services.nebula.networks.kulupu = {
    enable = true;
    ca   = "/var/secrets/nebula/kulupu/ca.crt";
    cert = "/var/secrets/nebula/kulupu/akesi.crt";
    key  = "/var/secrets/nebula/kulupu/akesi.key";
    firewall = {
      inbound = [
        { host = "any"; port = "any"; proto = "icmp"; }
      ];
      outbound = [
        { host = "musi"; port = "2049"; proto = "any"; }
        { host = "any"; port = "any"; proto = "icmp"; }
      ];
    };
    isLighthouse = true;
    settings = {};
  };
}
