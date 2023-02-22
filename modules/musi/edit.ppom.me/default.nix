{ lib, pkgs, config, ... }:
{
  imports = [
    ./pompeani.art/default.nix
    ./leborddeleau/default.nix
  ];

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
      </body>
    </html>
  '';

}
