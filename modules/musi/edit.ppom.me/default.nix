{ lib, pkgs, config, ... }:
{
  services.directus.servers = {
    "pompeani.art" = {
      enable = true;
      settings = {
        NULL_TEST = null;
        PORT = 8055;
        EMAIL_FROM = "directus@ppom.me";
        EMAIL_TRANSPORT = "smtp";
        EMAIL_SMTP_HOST = "mail.ppom.me";
        EMAIL_SMTP_PORT = 587;
        EMAIL_SMTP_SECURE = true;
        EMAIL_SMTP_USER = "directus@ppom.me";
        EMAIL_SMTP_PASSWORD_FILE = "/var/secrets/mail/directus";
      };
      nginx = {
        enable = true;
        serverName = "edit.ppom.me";
        location = "/pompeani.art";
      };
      # redis.enable = true;
      # redis.port = 8056;
    };
  };
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
