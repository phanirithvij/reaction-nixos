{ config, ... }:
{
  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users = {
    uploader = {
      isNormalUser = true;
      home = "/home/uploader";
      group = "nginx";
      openssh.authorizedKeys = config.users.users.ppom.openssh.authorizedKeys;
      extraGroups = [ "users" ];
    };
    bertille = {
      isNormalUser = true;
      group = "users";
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBrSvK7feOr37nP0hdOylZG1GzYBssHtVrWGs3/0zFha bertille@ordi"
      ];
    };
    media = {
      isNormalUser = true;
      group = "users";
      openssh.authorizedKeys = config.users.users.ppom.openssh.authorizedKeys;
    };
  };

  security.sudo-rs.extraRules = [
    {
      users = [
        "bertille"
        "ppom"
      ];
      runAs = "media";
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  systemd.services.uptime-calc = {
    description = "Saves uptime";
    serviceConfig.User = "ppom";
    script = ''uptime > ${config.users.users.ppom.home}/uptimes/$(date '+%y-%m-%d')'';
    startAt = "23:00:00";
  };

  nix.settings.allowed-users = [ "ppom" ];
}
