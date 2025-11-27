{ config, pkgs, ... }:
let
  var = import ../common/reaction-variables.nix { inherit config pkgs; };
  domain = "ppom.me";
  suffix = "/vault";
  rocketPort = 8060;
  websocketPort = 8061;

in
{
  services.vaultwarden = {
    enable = true;
    # secrets
    environmentFile = "/var/secrets/vaultwarden/env";
    dbBackend = "sqlite";
    config = {
      domain = "https://${domain}${suffix}";
      signupsAllowed = false;
      invitationsAllowed = true;
      rocketPort = rocketPort;
      websocketPort = websocketPort;
      websocketEnabled = true;
    };
  };

  services.nginx.virtualHosts."${domain}" = {
    forceSSL = true;
    enableACME = true;
    locations = {
      "${suffix}/" = {
        proxyPass = "http://localhost:${builtins.toString rocketPort}";
      };
      "${suffix}/notifications/hub" = {
        proxyPass = "http://localhost:${builtins.toString websocketPort}";
        proxyWebsockets = true;
      };
      "${suffix}/notifications/hub/negociate" = {
        proxyPass = "http://localhost:${builtins.toString rocketPort}";
      };
    };
  };

  services.reaction.settings.streams.vaultwarden = {
    cmd = [
      var.journalctl
      "-fn0"
      "-u"
      "vaultwarden.service"
    ];
    filters.failedlogin = {
      regex = [ ''Username or password is incorrect\. Try again\. IP: <ip>\. Username:'' ];
      retry = 3;
      retryperiod = "1h";
      actions = var.banFor "2h";
    };
  };
}
