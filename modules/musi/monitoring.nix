{ config, lib, pkgs, ... }:

let
  VARS= ''
    DATA_DIR="$HOME/.check_co/"
    DATA_FILE="$DATA_DIR/log"
    TEST_HOST="google.fr"
  '';

  check = pkgs.writeShellScriptBin "check_co.sh" ''
    ${VARS}

    ${pkgs.coreutils}/bin/mkdir -p $DATA_DIR

    ${pkgs.inetutils}/bin/ping -c2 -W3 $TEST_HOST &>/dev/null
    STAT=$?

    ${pkgs.coreutils}/bin/echo "$(date +%s) $STAT" | \
    ${pkgs.coreutils}/bin/tee -a $DATA_FILE
  '';

  print = pkgs.writeShellScriptBin "print_co.sh" ''
    ${VARS}

    # Print only first column of lines non ending with zero code
    # | Print the timestamp in a human-readable format
    ${pkgs.gawk}/bin/awk '! / 0$/ { print $1 }' $DATA_FILE | \
    ${pkgs.findutils}/bin/xargs -d'\n' -I'{}' date -d'@{}'
  '';
in {
  services.vnstat.enable = true;

  environment.etc."vnstat.conf".text = ''
    Interface enp6s0

    # Daemon

    BandwithDetection 1

    PollInterval 5

    TrafficlessEntries 1
    TopDayEntries 0

    5MinutesHours 168
    HourlyDays -1
    DailyDays -1
    MonthlyMonths -1
    YearlyYears -1

    # Output
  '';

  environment.systemPackages = [ check print ];

  systemd.services.check-co = {
    description = "Check if internet connection is up";
    serviceConfig = {
      User = "ppom";
      ExecStart = "${check}/bin/check_co.sh";
      LogNamespace = "noisy";
    };
    startAt = "minutely";
  };
  # Don't store check-co logging to disk
  environment.etc."systemd/journald@noisy.conf".text = ''
    [Journal]
    Storage=volatile
    RuntimeMaxUse=10M
  '';

  services.prometheus.exporters.node = {
    enable = true;
    enabledCollectors = ["systemd"];
  };

  services.victoriametrics = {
    enable = true;
    listenAddress = "127.0.0.1:8428";
    retentionPeriod = "4y";
    prometheusConfig = {
      scrape_configs = [
        {
          job_name = "node-exporter";
          metrics_path = "/metrics";
          static_configs = [
            {
              targets = ["localhost:9100"];
              labels.type = "node";
              labels.hostname = "musi.ppom.me";
            }
          ];
        }
      ];
    };
  };
  systemd.services.victoriametrics.serviceConfig = {
    MemoryMax = "100M";
  };

  services.grafana = {
    enable = true;
    settings = {
      security = {
        admin_user = "ppom";
        admin_password = "$" + "__file{/var/secrets/grafana/admin_password}";
      };
      server = {
        root_url = "https://ppom.me/grafana";
        serve_from_sub_path = true;
        protocol = "socket";
        path = "/run/grafana/grafana.sock";
        # socket_gid = config.users.groups.grafana.gid;
        socket_mod = "0660";
      };
    };
    declarativePlugins = [];

    provision = {
      enable = true;
      datasources.settings.datasources = [
        {
          url = "http://${config.services.victoriametrics.listenAddress}";
          name = "VictoriaMetrics";
          type = "victoriametrics";
          manageAlerts = true;
        }
        {
          url = "http://${config.services.victoriametrics.listenAddress}";
          name = "Prometheus";
          type = "prometheus";
          manageAlerts = true;
        }
      ];
      # dashboards.settings.providers = [
      #   {
      #     name = "node-exporter";
      #   }
      # ];
    };
  };

  users.users.nginx.extraGroups = [ config.users.users.grafana.group ];

  services.nginx.virtualHosts."ppom.me".locations."/grafana/" = {
    proxyPass = "http://unix:${config.services.grafana.settings.server.path}";
    proxyWebsockets = true;
  };
}
