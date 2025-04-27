{ pkgs, ... }:
{
  ppom.directus2zola.settings = {
    projects = [{
      name = "leborddeleau.net";
      script = [ "${pkgs.deno}/bin/deno" "run" "--allow-net" "./content.js" ];
      git_url = "https://framagit.org/ppom/leborddeleau.net.git";
      push_url = "musi-uploader@akesi.ppom.me:/var/www/leborddeleau.net/";
    }];
  };
}
