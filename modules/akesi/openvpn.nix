{ lib, config, pkgs, ... }:
let
  port = 443;
in {
  services.openvpn = {
    servers = {
      internetGateway = {
        config = ''
        '';
      };
      virtualLocalNetwork = {
      };
    };
  };
}
