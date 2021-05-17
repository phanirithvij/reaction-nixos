{ lib, pkgs, ... }:
let
  domainName = "croc.ppom.me";
  ports = [ 9009 9010 9011 9012 9013 ];
in {
  # User configuration
  users.users.croc = {
      isSystemUser = true;
      packages = with pkgs; [ croc ];
  };
  systemd.services.croc = {
    enable = true;
    description = "Croc relay";
    after = ["network.target"];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      User = "croc";
      ExecStart = ''${pkgs.croc}/bin/croc --ports ${lib.concatStringsSep (map toString ports)'';
    };
  };
}
