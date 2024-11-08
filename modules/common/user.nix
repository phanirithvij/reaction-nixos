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
        openssh.authorizedKeys.keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCjntXVcoGlrBwCkTWlsJk2uwCGjqToEX833hJQM9N85BazQ84sBGtMaRN8j9fSesEVcNz/YjIEbWcqq08aWnw4Qvg6Ns6fux7wvhNZWpOTB/6ApI0vI21R55lt7ZtH2neAOLkjmSuayhSPN9aJ4nvqkPQ133JHQr9Jvu6z8WqAahTVlphHtnsWtSe3cBw4U0vgXoKP/uRCTlA7p+pBbq0xOa0482Iii6aCsXFA2Ai9UzdkKQPtCe1upMZ/IMRC+esaVXsamjbIRffFoXgGXM7rP9aj+7IhHqrLwjmeLqXeQZsrvXE8Av+Zco0Wbtjy6Cg8oMuvMmIHuIr8v+LfOdBiwg6JsFSXq9PmL4OisaHjqiMKDktxRIjZI28kkuF9lBm7AYsNm5p78H1ccH5IXPcKKUaWDpaLswKNiYsOblTi0KWrMflPbg3IVPjyn0ms+ooDzbdJLl9UE6cf7zu3BqcyD/VIUvpTByNK3J+4So2xgStoxRwiVsvhzlCGc9fB+qE= ao@sona" ];
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
