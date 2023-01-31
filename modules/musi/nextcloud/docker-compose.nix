{
  toYaml
  , nextcloud
  # , collabora
}:
toYaml "docker-compose" {
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
      image = "postgres:13-alpine";
      restart = "always";
      container_name = "nc_pg";
      volumes = [ "db:/var/lib/postgresql/data" ];
      env_file = [ "/var/secrets/nextcloud-suite/db.env" ];
    };

    pgbackups = {
      image = "prodrigestivill/postgres-backup-local";
      restart = "always";
      container_name = "nc_pg_backup";
      volumes = [ "backups:/backups" ];
      links = [ "db" ];
      depends_on = [ "db" ];
      env_file = [ "/var/secrets/nextcloud-suite/db.env" ];
    };

    app = {
      image = "nextcloud:24-apache";
      restart = "always";
      container_name = nextcloud.dockerName;
      ports = [ "${nextcloud.port}:80" ];
      volumes = [ "/data/nextcloud/html:/var/www/html" ];
      env_file = [ "/var/secrets/nextcloud-suite/db.env" ];
      depends_on = [ "db" ];
    };
  };
}
