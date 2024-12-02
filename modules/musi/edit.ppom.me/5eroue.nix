{ lib, pkgs, config, ... }:
let
  directusPort = 8063;
  common = import ./common.nix {};
in {
  services.directus.servers = {
    "5eroue" = {
      enable = false;
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

  systemd.services.directus-5eroue.unitConfig = {
    ConditionPathExists = "!/var/lib/directus-5eroue/nostart";
  };

  services.nginx.virtualHosts."edit.ppom.me" = {
    locations = {
      "/5eroue/" = {
        extraConfig = "error_page 502 /5eroue/502.html;";
      };
      "/5eroue/502.html" = {
        root = pkgs.writeTextDir "/5eroue/502.html" ''
          <!DOCTYPE html>
          <head>
            <meta charset="utf-8">
          </head>
          <body>
            Le logiciel distant n'est pas démarré car le logiciel distant est actif.<br><br>
            Clique <a href='http://localhost'>
              ici
            </a> pour consulter le logiciel local.
          </body>
        '';
      };

    };

  };

  users.users."directus-5eroue" = {
    shell = pkgs.bashInteractive;
    openssh.authorizedKeys.keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDbkvImtAGpSFQ8XesQ21whnATnW1CjCsHgy6YUdWSwNz9QE6FEavlZUJHqcuYtrg5326+smwEhEV60JEMfkBXm7Og3pIthazBT51/4mjwytKXDo75OxH1Fp9lNmHR54Dde0CWZHEVufCFDNp8rVp+kEfcf8Lv73TyObMqkrnLdPym/cn3jBphV5z8xQg3sFsQ4R28GAhzplCwLAyTvvDLbzGZehM/SBuZH/54HxMFrn/AqUag98vPCePfkQW+PMb84xE8AbldULCO5A/uPCyns34zOjZ0guAigNp/lDVeQrloxt/PUoNjsUYYxNR5VDy50lkRZw8c63oqMqK3qPvzS4X+dTzYvxKwqyWeZPvqaHnq92Xj8vRI12t1qz3znj6IaeUKsv9kczIVjNLBZZCBNIcOEUJXUPSiA/Qr23sPZ76oCa5zOSZ5Sl0NUsWDRgokDSP+X4rcirAJ5xuTM/o7aBqxdBGHPXZcFXoRH2HPbQ6HmmabmNLv/tp2h3tzOqsM=" ];
    extraGroups = [ "directus" ];
  };

  security.doas.extraRules = let
    rule = cmd: {
      users = [ "directus-5eroue" ];
      noPass = true;
      cmd = "systemctl";
      args = [ cmd "directus-5eroue.service" ];
    };
  in [
    (rule "start")
    (rule "stop")
    (rule "reset-failed")
  ];
}
