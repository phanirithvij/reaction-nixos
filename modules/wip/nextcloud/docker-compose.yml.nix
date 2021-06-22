{
  pkgs
  # secrets
, dbEnvFile ? "/var/secrets/nextcloud-suite/db.env"
, mailEnvFile ? "/var/secrets/nextcloud-suite/mail.env"
  # setting file
  # domains
, nextcloudDomain ? "nuage.ppom.me"
, collaboraDomain ? "write.ppom.me"
  # ports
, nextcloudPort ? "9000"
, collaboraPort ? "9980"
  # volumes
, dbVolume ? "db"
, dbBackupVolume ? "backups"
, nextcloudVolume ? "/data/nextcloud/html"
}:
let
  loolwsd = pkgs.callPackage ./loolwsd.xml.nix {
    inherit nextcloudDomain collaboraDomain;
  };
in
pkgs.writeText "docker-compose.yml" (builtins.toJSON {
  version = "3";

  volumes = {
    db = null;
    backups = null;
  };

  networks = {
    proxy-tier = null;
  };

  services = {
    db = {
      image = "postgres:alpine";
      restart = "always";
      container_name = "nc_pg";
      volumes = [ "${dbVolume}:/var/lib/postgresql/data" ];
      env_file = [ dbEnvFile ];
    };

    pgbackups = {
      image = "prodrigestivill/postgres-backup-local";
      restart = "always";
      container_name = "nc_pg_backup";
      volumes = [ "${dbBackupVolume}:/backups" ];
      links = [ "db" ];
      depends_on = [ "db" ];
      env_file = [ dbEnvFile ];
    };

    app = {
      image = "nextcloud:apache";
      restart = "always";
      container_name = "nc_app";
      ports = [ "${toString nextcloudPort}:80" ];
      volumes = [ "${nextcloudVolume}:/var/www/html" ];
      env_file = [ dbEnvFile ];
      depends_on = [ "db" ];
    };

    collabora =
      let
        virtualport = collaboraPort;
      in {
      image = "collabora/code";
      container_name = "collabora";
      restart = "always";
      volumes = [
        "${loolwsd}:/etc/loolwsd/loolwsd.xml"
      ];
      ports = [ "${toString collaboraPort}:${toString virtualport}" ];
      cap_add = [ "MKNOD" ];
      environment = [
        "domain=${nextcloudDomain}"
        "VIRTUAL_HOST=${collaboraDomain}"
        "VIRTUAL_NETWORK=nginx-proxy"
        "VIRTUAL_PORT=${toString virtualport}"
        "DONT_GEN_SSL_CERT=true"
      ];
      networks = [ "proxy-tier" ];
    };

    mail = {
      image = "bytemark/smtp";
      container_name = "nc_mail";
      restart = "always";
      # ports = [ "25:25" ];
      ports = [ "1525" ];
      env_file = [ mailEnvFile ];
    };
  };
})
