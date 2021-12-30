{ lib, pkgs, ... }:
{
  services.postgresql = {
    enable = true;
    ensureDatabases = [ "idt" ];
    ensureUsers = [
      {
        name = "root";
        ensurePermissions = {
          "DATABASE idt" = "ALL PRIVILEGES";
        };
      }
    ];
  };
}
