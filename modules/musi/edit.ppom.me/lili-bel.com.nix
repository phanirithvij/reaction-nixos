{ lib, pkgs, config, ... }:
{
  ppom.directus2zola.settings.projects = [{
    name = "lili-bel.com";
    script = [ "${pkgs.deno}/bin/deno" "run" "--allow-net" "./content.js" ];
    git_url = "https://framagit.org/ppom/lili-bel.com.git";
    push_url = "musi-uploader@akesi.ppom.me:/var/www/static/lili";
  }];
}
