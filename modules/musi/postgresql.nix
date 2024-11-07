{ lib, config, pkgs, ... }:
{
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_14;
  };

  environment.systemPackages = let
    # specify the postgresql package you'd like to upgrade to.
    # Do not forget to list the extensions you need.
    newPostgres = pkgs.postgresql_14;
    updateScript = pkgs.writeShellScriptBin "upgrade-pg-cluster" ''
      set -eux
      # XXX it's perhaps advisable to stop all services that depend on postgresql
      systemctl stop postgresql

      export NEWDATA="/var/lib/postgresql/${newPostgres.psqlSchema}"

      export NEWBIN="${newPostgres}/bin"

      export OLDDATA="${config.services.postgresql.dataDir}"
      export OLDBIN="${config.services.postgresql.package}/bin"

      install -d -m 0700 -o postgres -g postgres "$NEWDATA"
      cd "$NEWDATA"
      sudo -u postgres $NEWBIN/initdb -D "$NEWDATA"

      sudo -u postgres $NEWBIN/pg_upgrade \
        --old-datadir "$OLDDATA" --new-datadir "$NEWDATA" \
        --old-bindir $OLDBIN --new-bindir $NEWBIN \
        "$@"
    '';
  in [
    # updateScript
  ];
}
