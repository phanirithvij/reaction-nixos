{ pkgs, ... }:
let
  directusPort = 8063;
  common = import ./common.nix { };
in
{
  services.directus.servers = {
    "5eroue" = {
      enable = true;
      settings = common.settings // {
        PORT = directusPort;
        LOG_LEVEL = "debug";
      };
      nginx = {
        enable = true;
        serverName = "edit.ppom.me";
        location = "/5eroue";
      };
    };
  };

  users.users."directus-5eroue".extraGroups = [ "directus" ];

  systemd.services.directus-5eroue-export = {
    enable = true;
    description = "Export data as CSV";
    wantedBy = [ "multi-user.target" ];
    path = [
      pkgs.coreutils
      pkgs.sqlite
    ];
    serviceConfig = {
      Type = "oneshot";
      User = "directus-5eroue";
      StateDirectory = "directus-5eroue";
      WorkingDirectory = "/var/lib/directus-5eroue";
      EnvironmentFile = "/var/secrets/export5eroue";
      ExecStart = [
        ''${pkgs.runtimeShell} -c "sqlite3 data.db < ${./5eroue.sql}"''
        ''+${pkgs.runtimeShell} -c "install -D -t $SECRET_PATH -o uploader -g nginx -m 640 *.csv"''
      ];
    };
    startAt = "hourly";
  };
}
