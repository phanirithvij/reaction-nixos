{ lib, config, pkgs, ... }:
let
  domain = "stats.ppom.me";
  port = 8000;
in {
  services.plausible = {
    enable = true;
    # default clickhouse settings
    # default postgres settings
    mail.email = "stats@ppom.me";
    adminUser = {
      activate = true;
      email = "paco@ecomail.io";
      passwordFile = "/var/secrets/plausible/adminPassword";
    };
    # default smtp settings
    server = {
      inherit port;
      baseUrl = "https://${domain}";
      secretKeybaseFile = "/var/secrets/plausible/frameworkSecret";
    };
    releaseCookiePath = "/var/secrets/plausible/releaseCookie";
  };

  services.nginx.virtualHosts."${domain}" = {
    forceSSL = true;
    enableACME = true;
    locations."/".proxyPass = "http://localhost:${builtins.toString port}";
  };

  services.postgresqlBackup.databases = [ "plausible" ];

  # clickhouse eats too much
  systemd.services.clickhouse.serviceConfig = {
    CPUWeight = 20;
    StartupCPUWeight = 100;
  };

  # See PR #186667
  environment.etc."clickhouse-server/config.d/logging.xml".text = ''
    <clickhouse>
      <logger>
        <level>notice</level>
      </logger>
    </clickhouse>
  '';

  # See PR #186660
  systemd.services.clickhouse.serviceConfig.ExecStart = lib.mkForce "${config.services.clickhouse.package}/bin/clickhouse-server --config-file=/etc/clickhouse-server/config.xml";

  # See PR #186674
  systemd.services.plausible.after = [ "clickhouse.service" ];
}

