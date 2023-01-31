{ lib, pkgs, config, ... }:
let
  directusPort = 8055;
  d2zPort = 8056;
in {
  services.directus.servers = {
    "pompeani.art" = {
      enable = true;
      settings = {
        PORT = directusPort;
        EMAIL_FROM = "directus@ppom.me";
        EMAIL_TRANSPORT = "smtp";
        EMAIL_SMTP_HOST = "mail.ppom.me";
        EMAIL_SMTP_PORT = 465;
        EMAIL_SMTP_SECURE = true;
        EMAIL_SMTP_USER = "postmaster@ppom.me";
        EMAIL_SMTP_PASSWORD_FILE = "/var/secrets/mail/postmaster"; # Must not end with a newline
      };
      nginx = {
        enable = true;
        serverName = "edit.ppom.me";
        location = "/pompeani.art";
      };
    };
  };

  users.users."directus-pompeani.art".extraGroups = [ "postmaster" ];

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

  programs.ssh.knownHostsFiles = [
    (pkgs.writeText "akesi"
    "akesi.ppom.me ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOrvqULNbWvvsOKt0pSoEMfpK6ototDyU3bncfGCkj6C")
  ];

  users.users."directus2zola-pompeani.art" = {
    isSystemUser = true;
    group = "directus2zola-pompeani.art";
  };
  users.groups."directus2zola-pompeani.art" = {};

  systemd.services."directus2zola-pompeani.art" = {
    enable = true;
    wantedBy = [ "multi-user.target" ];
    requires = [ "directus-pompeani.art.service" ];
    after = [ "directus-pompeani.art.service" ];
    path = with pkgs; [ nodejs git zola rsync openssh ];
    serviceConfig = {
      Slice = "directus.slice";
      User = "directus2zola-pompeani.art";
      Group = "directus2zola-pompeani.art";
      Environment = [
        "D2Z_PORT=${builtins.toString d2zPort}"
        "D2Z_SSH_KEY=/var/secrets/pompeani.art/key"
        "D2Z_SSH_DEST=pompeani.art-uploader@akesi.ppom.me:/var/www/pompeani.art/"
      ];
      StateDirectory =            "directus2zola-pompeani.art";
      WorkingDirectory = "/var/lib/directus2zola-pompeani.art";
      ExecStartPre = pkgs.writeScript "directus2zola-pompeani.art-prestart" ''
        #!${pkgs.runtimeShell}
        set -e
        rm -f node_modules package.json index.js
        cat ${config.services.directus.installDirectory}/package.json | \
          ${pkgs.jq}/bin/jq \
            '.type = "module" | .main = "index.js"' \
          > package.json
        ln -s ${config.services.directus.installDirectory}/node_modules ./node_modules
        cp ${./directus2zola.js} ./index.js
        [[ -e zola ]] || git clone https://framagit.org/ppom/pompeani.art.git zola
      '';
      ExecStart = "${pkgs.nodejs}/bin/node ./index.js";
      Restart = "always";
      RestartSec = 10;
      LockPersonality = true;
      NoNewPrivileges = true;
      PrivateDevices = true;
      PrivateMounts = true;
      PrivateTmp = true;
      PrivateUsers = true;
      ProtectClock = true;
      ProtectControlGroups = true;
      ProtectHome = true;
      ProtectHostname = true;
      ProtectKernelLogs = true;
      ProtectKernelModules = true;
      ProtectKernelTunables = true;
      ProtectProc = "invisible";
      ProtectSystem = "strict";
      RemoveIPC = true;
      RestrictNamespaces = true;
      RestrictSUIDSGID = true;
    };
  };
}
