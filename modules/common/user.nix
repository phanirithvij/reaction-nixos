{ config, lib, pkgs, ... }:
{
  options.ppom.user = {
    enable = lib.mkEnableOption "enable ppom user";
    fish = lib.mkEnableOption "use fish as shell";
  };

  config = lib.mkIf config.ppom.user.enable (lib.mkMerge [
    {
      users.users.ppom = {
        isNormalUser = true;
        group = "users";
        extraGroups = [
          "wheel"
          "users"
        ];
        openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF6/aTJkkYdrOX0WdqoB+EN0ZFjdWtIz1oczVN8oxHbP ppom" ];
      };
    }
    (lib.mkIf config.ppom.user.fish {
      users.users.ppom.shell = pkgs.fish;
      users.groups.users = {};
      programs.fish.enable = true;
      environment.pathsToLink = [ "/share/fish" ];
    })
  ]);
}
