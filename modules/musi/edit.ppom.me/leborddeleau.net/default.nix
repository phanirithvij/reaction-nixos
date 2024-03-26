{ lib, pkgs, config, ... }:
let
  directusPort = 8057;
  d2zPort = 8059;
  common = import ../common.nix {};
in {
  services.directus.servers = {
    "leborddeleau" = {
      enable = true;
      settings = common.settings // {
        PORT = directusPort;
      };
      nginx = {
        enable = true;
        serverName = "edit.ppom.me";
        location = "/leborddeleau";
      };
    };
  };

  users.users."directus-leborddeleau".extraGroups = [ "postmaster" ];

  ppom.directus2zola.settings = {
    projects = [{
      name = "leborddeleau.net";
      script = [ "${pkgs.deno}/bin/deno" "run" "--allow-net" ./leborddeleau.net.js ];
      git_url = "https://framagit.org/ppom/leborddeleau.net.git";
      push_url = "musi-uploader@akesi.ppom.me:/var/www/static/bdo/";
    }];
  };
}
