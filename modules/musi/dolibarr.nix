{ lib, pkgs, ... }:
{
  services.dolibarr = {
    enable = true;
    database = {
      createLocally = true;
    };
    domain = "dolibarr.ppom.me";
    nginx = {};
  };

  services.mysqlBackup.databases = [ "dolibarr" ];
}
