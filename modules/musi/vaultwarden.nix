{ lib, config, pkgs, ... }:
let 
  unstable = import <nixos-unstable> {};
  domain = "ppom.me";
  suffix = "/vault";
  rocketPort = 8060;
  websocketPort = 8061;

  fail2banFilter = pkgs.writeText "vaulwardenFail2banFilter.conf" ''
    [INCLUDES]
    before = common.conf

    [Definition]
    failregex = ^.*Username or password is incorrect\. Try again\. IP: <ADDR>\. Username:.*$
    ignoreregex =
    journalmatch = _SYSTEMD_UNIT=vaultwarden.service + _COMM=vaultwarden
  '';
in {
  services.vaultwarden = {
    enable = true;
    package = unstable.vaultwarden;
    webVaultPackage = unstable.vaultwarden.webvault;
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

  # fail2ban
  environment.etc."fail2ban/filter.d/vaultwarden.conf".source = fail2banFilter;

  services.fail2ban.jails.vaultwarden = ''
    enabled = true
    port = 80,443
    filter = vaultwarden

    maxretry = 3
    findtime = 3600
    bantime = 2400
  '';

  systemd.services.fail2ban.restartTriggers = [ fail2banFilter ];
}
