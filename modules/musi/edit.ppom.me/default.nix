{ lib, pkgs, config, ... }:
let
  var = import ../../common/reaction-variables.nix { inherit pkgs; };
in
{
  imports = [
    ./directus2zola.nix
    ./pompeani.art/default.nix
    ./leborddeleau.net/default.nix
    ./5eroue/default.nix
    ./edit.ppom.fr/default.nix
    # ./n8n.nix
    # ./ecotheque/default.nix
    # ./chatons/default.nix
  ];

  services.directus.allowDirectusLicense = true;

  programs.ssh.knownHostsFiles = [
    (pkgs.writeText "akesi"
    "akesi.ppom.me ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOrvqULNbWvvsOKt0pSoEMfpK6ototDyU3bncfGCkj6C")
  ];

  services.nginx.virtualHosts."edit.ppom.me".root = pkgs.writeTextDir "index.html" ''
    <!DOCTYPE html>
    <html>
      <head>
        <meta charset="utf8">
        <title>Sites d'édition Directus</title>
      </head>
      <body>
        <h1>Sites d'édition Directus</h1>
        <ul>
          <li><a href="/pompeani.art">Pompeani.art</a></li>
          <li><a href="/leborddeleau">Le bord de l'eau</a></li>
          <li><a href="/5eroue">La 5e Roue</a></li>
        </ul>
      </body>
    </html>
  '';

  services.reaction.settings.streams.nginx.filters."directusFailedLogin" = {
    regex = [
      ''^<ip> .* "POST /repertoire/auth/login HTTP/..." 401 [0-9]+ .https://babos.land''
      # ''^<ip> .* "POST /ecotheque/auth/login HTTP/..." 401 [0-9]+ .https://edit.ppom.me''
      ''^<ip> .* "POST /pompeani.art/auth/login HTTP/..." 401 [0-9]+ .https://edit.ppom.me''
      ''^<ip> .* "POST /leborddeleau/auth/login HTTP/..." 401 [0-9]+ .https://edit.ppom.me''
      # ''^<ip> .* "POST /chatons/auth/login HTTP/..." 401 [0-9]+ .https://edit.ppom.me''
      ''^<ip> .* "POST /5eroue/auth/login HTTP/..." 401 [0-9]+ .https://edit.ppom.me''
      ''^<ip> .* "POST /edit/auth/login HTTP/..." 401 [0-9]+ .https://edit.ppom.me''
      ''^<ip> .* "POST /auth/login HTTP/..." 401 [0-9]+ .https://edit.ppom.fr''
    ];
    retry = 6;
    retryperiod = "4h";
    actions = var.banFor "4h";
  };

  users.groups.directus2zola = {};
}
