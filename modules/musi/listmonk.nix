{ lib, config, pkgs, ... }:
let
  listmonkPort = 9000;
  listmonkBasicAuthFile = "/var/secrets/basic_auth_nginx/monit";
in {
  # services.listmonk = {
  #   enable = true;
  #   database = {
  #     createLocally = true;
  #   };
  #   settings = {
  #     app.address = "0.0.0.0:${builtins.toString listmonkPort}";
  #     app.admin_username = "admin";
  #   };
  #   secretFile = "/var/secrets/listmonk";
  # };

  # services.postgresqlBackup.databases = [ "listmonk" ];

  # services.nginx.virtualHosts."mail.ppom.me" = {
  #   enableACME = true;
  #   forceSSL = true;
  #   locations."/" = {
  #     proxyPass = "http://localhost:${builtins.toString listmonkPort}";
  #     # extraConfig = ''auth_basic "Credentials"; auth_basic_user_file ${listmonkBasicAuthFile};'';
  #   };
  # };
}
