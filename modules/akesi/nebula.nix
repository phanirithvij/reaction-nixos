{ lib, config, pkgs, ... }:
{
  # networking.firewall.allowedUDPPorts = [ 4242 ];
  # services.nebula.networks.kulupu = {
  #   enable = true;
  #   ca   = "/var/secrets/nebula/kulupu/ca.crt";
  #   cert = "/var/secrets/nebula/kulupu/akesi.crt";
  #   key  = "/var/secrets/nebula/kulupu/akesi.key";
  #   firewall = {
  #     inbound = [
  #       { host = "any"; port = "any"; proto = "any"; }
  #     ];
  #     outbound = [
  #       { host = "any"; port = "any"; proto = "any"; }
  #     ];
  #   };
  #   isLighthouse = true;
  #   settings = {};
  # };
}
