{ config, pkgs, ... }:
{
  # services.nfs.server = {
  #   enable = true;
  #   exports = ''
  #     /data/user-uploads/akesi 192.168.100.1(rw,nohide,insecure,no_subtree_check)
  #   '';
  # };

  # networking.firewall.allowedUDPPorts = [ 4242 ];
  # systemd.services."nebula@kulupu".serviceConfig.ReadOnlyPaths = [ "/var/secrets/nebula/kulupu/" ];
  # services.nebula.networks.kulupu = {
  #   enable = true;
  #   ca   = "/var/secrets/nebula/kulupu/ca.crt";
  #   cert = "/var/secrets/nebula/kulupu/musi.crt";
  #   key  = "/var/secrets/nebula/kulupu/musi.key";
  #   firewall = {
  #     outbound = [
  #       { host = "any"; port = "any"; proto = "any"; }
  #     ];
  #     inbound = [
  #       { host = "any"; port = "any"; proto = "any"; }
  #     ];
  #   };
  #   isLighthouse = true;
  #   staticHostMap = { "192.168.100.1" = [ "54.37.74.51:4242" ]; };
  #   settings = {
  #     lighthouse = {
  #       hosts = "192.168.100.1";
  #     };
  #   };
  # };
}
