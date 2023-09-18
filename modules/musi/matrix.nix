{ lib, pkgs, ... }:
let
  # default port
  port = 6167;
in {
  networking.firewall.allowedTCPPorts = [ 8448 ];

  services.nginx.virtualHosts."ppom.me" = {
    # add 8448 matrix federation port
    listen = [
      { addr = "0.0.0.0"; port = 80;   ssl = false; }
      { addr = "[::]";    port = 80;   ssl = false; }
      { addr = "0.0.0.0"; port = 443;  ssl = true; }
      { addr = "[::]";    port = 443;  ssl = true; }
      { addr = "0.0.0.0"; port = 8448; ssl = true; }
      { addr = "[::]";    port = 8448; ssl = true; }
    ];

    locations."/_matrix/" = {
      proxyPass = "http://localhost:6167";
      proxyWebsockets = true;
    };

    # locations."/matrix/" = {
    #   root = pkgs.linkFarm "fluffychat-in-subdirectory" [ {
    #     name = "matrix";
    #     path = (pkgs.callPackage ../../pkgs/fluffychat-web { baseHref = "/matrix/"; });
    #   } ];
    # };

    locations."/matrix".return = "301 /matrix/";
    # extraConfig = "merge_slashes off;";
  };

  services.matrix-conduit = {
    enable = true;
    settings.global = {
      address = "127.0.0.1";
      allow_registration = false;
      server_name = "ppom.me";
      trusted_servers = [ "matrix.org" "club1.fr" "deuxfleurs.fr" ];
    };
  };
}
