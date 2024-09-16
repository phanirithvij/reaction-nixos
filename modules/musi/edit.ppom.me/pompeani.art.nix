{ lib, pkgs, config, ... }:
let
  directusPort = 8055;
  d2zPort = 8056;
  common = import ./common.nix {};
in {
  services.directus.servers = {
    "pompeani.art" = {
      enable = true;
      settings = common.settings // {
        PORT = directusPort;
      };
      nginx = {
        enable = true;
        serverName = "edit.ppom.me";
        location = "/pompeani.art";
      };
    };
  };

  users.users."directus-pompeani.art".extraGroups = [ "directus" ];

  ppom.directus2zola.settings = {
    projects = [{
      name = "pompeani.art";
      script = [ "${pkgs.deno}/bin/deno" "run" "--allow-net" "./content.js" ];
      git_url = "https://framagit.org/ppom/pompeani.art.git";
      push_url = "musi-uploader@akesi.ppom.me:/var/www/pompeani.art/";
    }];
  };
}
