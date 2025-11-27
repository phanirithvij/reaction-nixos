{
  lib,
  config,
  pkgs,
  ...
}:
{
  # services.postgresql = {
  #   enable = true;
  #   package = pkgs.postgresql_16;
  #   ensureDatabases = [ "peertube-dev" ];
  #   ensureUsers = [ {
  #     name = "peertube-dev";
  #     ensureDBOwnership = true;
  #   } ];
  # };
  # services.redis.servers.peertube-dev = {
  #   enable = true;
  #   unixSocketPerm = 666;
  # };

  # systemd.services.postgresql.wantedBy = lib.mkForce [];
  # systemd.services.redis-peertube-dev = {
  #   wantedBy = lib.mkForce [];
  #   serviceConfig.RuntimeDirectoryMode = lib.mkForce 0777;
  # };
}
