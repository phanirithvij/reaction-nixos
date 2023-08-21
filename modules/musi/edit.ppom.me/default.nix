{ lib, pkgs, config, ... }:
let
  var = import ../../common/reaction-variables.nix { inherit pkgs; };
in
{
  imports = [
    ./ecotheque/default.nix
    ./pompeani.art/default.nix
    ./leborddeleau/default.nix
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
        <a href="/pompeani.art">pompeani.art</a>
        <a href="/leborddeleau">Le bord de l'eau</a>
      </body>
    </html>
  '';

  services.reaction.settings.streams.nginx.filters."directusFailedLogin" = {
    regex = [
      ''^<ip> .* "POST /repertoire/auth/login HTTP/..." 401 [0-9]+ .https://babos.land''
      ''^<ip> .* "POST /ecotheque/auth/login HTTP/..." 401 [0-9]+ .https://edit.ppom.me''
      ''^<ip> .* "POST /pompeani.art/auth/login HTTP/..." 401 [0-9]+ .https://edit.ppom.me''
      ''^<ip> .* "POST /leborddeleau/auth/login HTTP/..." 401 [0-9]+ .https://edit.ppom.me''
    ];
    retry = 6;
    retry-period = "4h";
    actions = var.banFor "4h";
  };
}
