{ config, pkgs, ... }:
{
  services.nginx = {
    enable = true;
    virtualHosts."vps-30fe5ba1.vps.ovh.net" = {
      default = true;
      locations."/".root = "/var/www/";
    };
  };
  # TEST ONLY
  networking.firewall.allowedTCPPorts = [ 80 ];
}
