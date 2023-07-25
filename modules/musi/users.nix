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
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDcO2E3P+kOXto9zUkn2Qq2ykJtZlgrb+JQYzs9w0mc/NoRZpOqQn1giiXPBcijhE2s+t8Y2Je5383sZUgaqqlPOsfo99FZmor+CVb5+V0fmH9Czeduxdxr1OQJ+1BUxsLe2k/bSg/wMz4cdMYvO2I2sEf3xY9Ofz6WxUvWTb6F65719bHw4FOPkcl6CaieWzfH/3mQ/Rlev7y0aNhzYQO6Sl1pf22/r3RjtHAAF1rKZ5HvS1SflLj2JsQ2OmhU1i8bD5NGi2nnZEoojWVYIxrY79hCku2TX5b+pPHU4i38nXowL8KUMKlbi3Fiv1JnK8y87Vj9IN53v02V5130na9r bertille"
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDQoTXXtmp4TxSzZOTjldYPpr7eNSd/6HUuJVoKEVZ45LbsTT+7rcg6tCPVqpj82wxqhMHqTxuRvGnzu0j9kxxmrr/8g+WvQGiY9HQ/NrDyYOItDv/mExMqOjaJeM36mefKzd+g4UlsHT9xdL6wB9940XzuAvsz9XQKFGf/Rfc6rSH87SHJGn2BCqXEdHyfA3MSfhnBZ8CJNaNP3b4t3QXCQ+dzghsVnP4x9hJ9Fa1csLWB7UCxXnpWcYeEJmb/Gf6VtDWntJ8KuURZe+pYtWcpFv+tMFvo0G9elphJ1wx8HbGq2S7g1fA8kuzBjvjL5YEHn4oAvNJKDnXAehZGC2wWcepUYr+caeIJRe8Bu/qDSGVGjD0vtcnPNvKSS2t3UWjEtnUmBaqOIiHVRrrrvUA1Z/A2I1/Rvujy9cV6E3tiht+UcfQ9Maq/QsTfHxIiECDYeDZxSMJ/EulL9Rp1QACMYY36L1oDWwjHphpI1scIa0wC4dBMKVa1LLFpRq0ccx2O36j7b/QwXIB53nJbVW3nwzV3Yza9R+WoMTtE1BtRHf0f+VCbmvIR7QwvcW4L3yWwRzxI5Yap4CftKncu+fthuF1Sdby/olWEryGaVYiTLKq2xUGzweytaIT3ab1UK2i02I/TWLDQFviQdZfVxGDzgloP6vdnjBZIFjWA2+0ABQ== bertille"
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
