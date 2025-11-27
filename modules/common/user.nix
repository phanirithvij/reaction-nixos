{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.ppom.user = {
    enable = lib.mkEnableOption "enable ppom user";
    fish = lib.mkEnableOption "use fish as shell";
    musi = lib.mkEnableOption "enable musi user";
    bertille = lib.mkEnableOption "enable bertille user";
  };

  config = lib.mkIf config.ppom.user.enable (
    lib.mkMerge [
      {
        users.users.ppom = {
          isNormalUser = true;
          group = "users";
          extraGroups = [
            "wheel"
            "users"
          ];
          openssh.authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF6/aTJkkYdrOX0WdqoB+EN0ZFjdWtIz1oczVN8oxHbP ppom"
          ];
        };
      }
      (lib.mkIf config.ppom.user.fish {
        users.users.ppom.shell = pkgs.fish;
        users.groups.users = { };
        programs.fish.enable = true;
        environment.pathsToLink = [ "/share/fish" ];
      })
      (lib.mkIf config.ppom.user.musi {
        users.users.musi = {
          isNormalUser = true;
          extraGroups = [ "users" ];
          openssh.authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMejg0vhFiS9vjVYX8IiXgq4kRy8c+XXbkaaio6i4BXP root@musi"
          ];
        };
      })
      (lib.mkIf config.ppom.user.bertille {
        users.users.bertille = {
          isNormalUser = true;
          extraGroups = [ "users" ];
          openssh.authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBrSvK7feOr37nP0hdOylZG1GzYBssHtVrWGs3/0zFha pc"
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDADyVfLZCsO8jsspVQW8ZyTSTCIgsHL1I0zh4GUjs+X server"
          ];
        };
      })
    ]
  );
}
