{ config, pkgs, ... }:
let
  ppomKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCjntXVcoGlrBwCkTWlsJk2uwCGjqToEX833hJQM9N85BazQ84sBGtMaRN8j9fSesEVcNz/YjIEbWcqq08aWnw4Qvg6Ns6fux7wvhNZWpOTB/6ApI0vI21R55lt7ZtH2neAOLkjmSuayhSPN9aJ4nvqkPQ133JHQr9Jvu6z8WqAahTVlphHtnsWtSe3cBw4U0vgXoKP/uRCTlA7p+pBbq0xOa0482Iii6aCsXFA2Ai9UzdkKQPtCe1upMZ/IMRC+esaVXsamjbIRffFoXgGXM7rP9aj+7IhHqrLwjmeLqXeQZsrvXE8Av+Zco0Wbtjy6Cg8oMuvMmIHuIr8v+LfOdBiwg6JsFSXq9PmL4OisaHjqiMKDktxRIjZI28kkuF9lBm7AYsNm5p78H1ccH5IXPcKKUaWDpaLswKNiYsOblTi0KWrMflPbg3IVPjyn0ms+ooDzbdJLl9UE6cf7zu3BqcyD/VIUvpTByNK3J+4So2xgStoxRwiVsvhzlCGc9fB+qE= ao@sona";
in {
  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users = {
    ppom = {
      isNormalUser = true;
      group = "users";
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = [ ppomKey ];
    };
    uploader = {
      isNormalUser = true;
      home = "/home/uploader";
      group = "nginx";
      openssh.authorizedKeys.keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC+QKvUjiZ4MnIzGaWJjVevXyEc8Ja3aORPE+gSYgBGwVOPK5SR9oQPyeBFQWjRuY9HeCarKoCWC4X7n0yg1hcYmFs4U7Tm1eb179+YYXIW2KPZOLrVBrAWzNTUPhcToo1/zsnLmFKbU/Kn/lt0YHo0pfDfRE1mFi2ORIEtyqg6nCeZkcb5DfunXG6lEejTm41aDoxs3UjqSBStP0GmX5ReVENRUxo0UzPcW1ImXLhD5A2BcOXvbaUp1lMWVfqY28gbYVDMbYyqDfMA3+yacXKoQcUwgDC9tKKzaxWuuYs/y+vVM01aARK7ol++9f5b1205LNDRVzzUIezrDZsWcggclcCaeKFy2rOBsVHj4wuMp9+M4NWF0NKetJsFOkas4BNUJXhSuGrhtvVeqQBtgtSt6gH7hRmPp/NZpG7OniK2g7Zm/jFte8aOPNWZL0iKv2fLNdPkgdx63MjgVDu5L1Z7I6kIvTBIRluLnzoOdsEWBm/9y0SacCsyRJKA2kPXfmc= ao@sona" ];
      extraGroups = [ "users" ];
    };
    bertille = {
      isNormalUser = true;
      group = "users";
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBrSvK7feOr37nP0hdOylZG1GzYBssHtVrWGs3/0zFha bertille@ordi"
      ];
    };
    media = {
      isNormalUser = true;
      group = "users";
      openssh.authorizedKeys.keys = [ ppomKey ];
    };
  };

  security.doas.extraRules = [ {
    users = [ "bertille" "ppom" ];
    runAs = "media";
    noPass = true;
  } ];

  systemd.services.uptime-calc = {
    description = "Saves uptime";
    serviceConfig.User = "ppom";
    script = ''uptime > ${config.users.users.ppom.home}/uptimes/$(date '+%y-%m-%d')'';
    startAt = "23:00:00";
  };

  nix.settings.allowed-users = [ "ppom" ];
}
