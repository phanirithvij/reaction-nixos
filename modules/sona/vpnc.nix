{ lib, pkgs, ... }:

{
  environment = {
    systemPackages = [ pkgs.vpnc ];
    etc."vpnc/default.conf".text = ''
      IPSec gateway vpnssl.utc.fr
      IPSec ID etu
      IPSec secret vpnaccess
      Xauth username ppompean
    '';
  };
}
