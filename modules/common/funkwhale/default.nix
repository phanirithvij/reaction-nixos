# Create & network to reach host                            ↓ host ip on the network
# docker network create -d bridge --subnet 192.168.0.0/24 --gateway 192.168.0.1 mynet
# containers on this network will access to the host, for example to connect to a database
{ lib, pkgs, config, ... }:
{
  options.services.funkwhale = with lib; with types; {
    enable = mkEnableOption "enable Funkwhale using docker-compose";

    domainName = mkOption {
      type = str;
      description = "Domain you want to use";
    };

    funkwhaleVersion = mkOption {
      type = str;
      description = "Funkwhale version on Docker hub";
    };

    # TODO fix this. the option doesn't work, i didn't manage to change the port number (always 5000)
    hostPort = mkOption {
      type = int;
      description = "Port to expose on the host";
      default = 5000;
    };

    hostPortFront = mkOption {
      type = int;
      description = "Port to expose on the host for the frontend";
      default = 4999;
    };

    musicDir = mkOption {
      type = str;
      description = "Path to your music directory";
    };

    mediaDir = mkOption {
      type = str;
      description = "Path to the data directory";
      default = "/var/lib/funkwhale/media";
    };

    maxBodySize = mkOption {
      type = str;
      description = "Max upload size. Handled by nginx";
      default = "100M";
    };

    autoScan = {
      enable = mkOption {
        type = bool;
        default = false;
        description = "enable regular scan of subscribed libraries";
      };

      passwordFile = mkOption {
        type = str;
        description = mdDoc ''
          An env file containing the generated token in the user's settings.
          Needs permissions `read:follows` and `write:libraries`.
          ```bash
          TOKEN=the-generated-token
          ```
        '';
      };

      startAt = mkOption {
        type = str;
        description = mdDoc "When to launch the scans. Must be in the format described in `systemd.time`";
        default = "weekly";
      };
    };
  };

  config = let
    cfg = config.services.funkwhale;

    localVars = let 
      secretsDir = "/var/lib/funkwhale/secrets";
    in {
      redisPort = 8325;
      inherit secretsDir;
      redisSecretFile = "${secretsDir}/redis.secret";
      postgresSecretFile = "${secretsDir}/postgres.secret";
      pythonSecretFile = "${secretsDir}/env.secret";
      # filled by the API container, served by host NGINX
      frontendDir = "/var/lib/funkwhale/frontend";
      staticDir = "/var/lib/funkwhale/static";
    };

    pythonEnv = {
      # We're in production lol
      DJANGO_SETTINGS_MODULE = "config.settings.production";
      # Basic shit
      FUNKWHALE_HOSTNAME = cfg.domainName;
      FUNKWHALE_PROTOCOL = "https";
      FUNKWHALE_API_IP = "127.0.0.1";
      FUNKWHALE_API_PORT = toString cfg.hostPort;
      FUNKWHALE_WEB_WORKERS = "4";
      THROTTLING_RATES = "subsonic=5000/h";
      LOG_LEVEL = "error";
      NESTED_PROXY = "1";
      REVERSE_PROXY_TYPE = "nginx";
      NGINX_MAX_BODY_SIZE = cfg.maxBodySize;
      MUSIC_DIRECTORY_SERVE_PATH = cfg.musicDir;
      MUSIC_DIRECTORY_PATH = "/music";
      STATIC_ROOT = "/static";
      MEDIA_ROOT = "/media";
      # DEFAULT_FROM_EMAIL = "noreply@yourdomain";
    };

    dockerServiceOverrides = {
      after = [ "funkwhale-init.service" ];
    };

  in lib.mkIf cfg.enable {

    assertions = [
      {
        assertion = cfg.autoScan.enable -> (cfg.autoScan.passwordFile != null && cfg.autoScan.startAt != null);
        message = "if you enable autoScan, you must set its parameters";
      }
    ];

    users = {
      users.funkwhale = {
        isSystemUser = true;
        group = "funkwhale";
        uid = 988;
      };
      groups.funkwhale = {
        gid = 984;
      };
    };

    systemd.tmpfiles.rules = [
      "d ${localVars.secretsDir} 755 root root - -"
      "d /var/lib/funkwhale 755 funkwhale funkwhale - -"
      "d ${localVars.staticDir} 755 funkwhale funkwhale - -"
      "Z ${localVars.staticDir} 755 funkwhale funkwhale - -"
    ];

    systemd.services = {
      funkwhale-init = {
        enable = true;
        description = "Secret generation for Funkwhale";
        wantedBy = [ "multi-user.target" ];
        after = [ "postgresql.service" ];
        before = [ "redis.service" ];
        serviceConfig = {
          Type = "oneshot";
          User = "root";
        };
        path = [ pkgs.libressl pkgs.postgresql ];
        # TODO reload redis?
        script = with localVars; ''
          genPasswd() {
            # tr -cd '[:alnum:]' < /dev/urandom | fold -w30 | head -n1
            openssl rand -base64 32 | tr -cd '[:alnum:]'
          }

          if test '!' -f ${pythonSecretFile}
          then
            echo Generating secrets…
            REDIS_PASSWORD=$(genPasswd)
            POSTGRES_PASSWORD=$(genPasswd)
            DJANGO_PASSWORD=$(genPasswd)
            touch ${redisSecretFile} ${postgresSecretFile} ${pythonSecretFile}
            chmod 640 ${redisSecretFile} ${postgresSecretFile} ${pythonSecretFile}
            chown root:funkwhale ${pythonSecretFile}
            chown root:redis-funkwhale ${redisSecretFile}
            chown root:postgres ${postgresSecretFile}

            /run/wrappers/bin/su -c \
              "psql -c \"ALTER USER funkwhale WITH PASSWORD '$POSTGRES_PASSWORD';\"" \
              postgres

            echo $REDIS_PASSWORD > ${redisSecretFile}
            echo $POSTGRES_PASSWORD > ${postgresSecretFile}
            cat > ${pythonSecretFile} <<EOF
          CACHE_URL=redis://:$REDIS_PASSWORD@localhost:${toString redisPort}/0
          DJANGO_SECRET_KEY=$DJANGO_PASSWORD
          DATABASE_URL=postgresql://funkwhale:$POSTGRES_PASSWORD@localhost:${toString config.services.postgresql.port}/funkwhale
          EOF
          fi
        '';
      };

      docker-funkwhale-api = dockerServiceOverrides;
      docker-funkwhale-celeryworker = dockerServiceOverrides;
      docker-funkwhale-celerybeat = dockerServiceOverrides;
      docker-funkwhale-front = {
        after = [ "docker-funkwhale-api.service" ];
      };
    };

    virtualisation.oci-containers = {
      backend = "docker";

      containers = let
        basicOptions = {
          autoStart = true;
          extraOptions = [ "--network" "host" ]; # to connect to postgresql
          image = "funkwhale/front:${cfg.funkwhaleVersion}";
          environment = pythonEnv;
        };
        pythonOptions = basicOptions // {
          user = "${toString config.users.users.funkwhale.uid}:${toString config.users.groups.funkwhale.gid}";
          image = "funkwhale/api:${cfg.funkwhaleVersion}";
          environmentFiles = [ localVars.pythonSecretFile ];
        };
        mediaVolumes = [
            "${cfg.musicDir}:/music:ro"
            "${cfg.mediaDir}:/${pythonEnv.MEDIA_ROOT}"
        ];
        codeVolumes = [
            "${localVars.frontendDir}:/frontend"
            "${localVars.staticDir}:${pythonEnv.STATIC_ROOT}"
        ];
      in {
        funkwhale-celeryworker = pythonOptions // {
          cmd = [ "celery" "-A" "funkwhale_api.taskapp" "worker" "-l" "INFO" "--concurrency=8" ];
          volumes = mediaVolumes;
        };

        funkwhale-celerybeat = pythonOptions // {
          cmd = [ "celery" "-A" "funkwhale_api.taskapp" "beat" "--pidfile=" "-l" "INFO" "-s" "/tmp/celerybeat-schedule" ];
        };

        funkwhale-api = pythonOptions // {
          volumes = mediaVolumes ++ codeVolumes ++ [
            "${./merge-funkwhale-artists.py}:/app/merge-funkwhale-artists.py:ro"
            "${./merge-funkwhale-tracks.py}:/app/merge-funkwhale-tracks.py:ro"
          ];
        };

        funkwhale-front = basicOptions // {
          volumes = mediaVolumes ++ codeVolumes ++ [
            "${pkgs.writeScript "edit-upstream" ''
              #!/bin/sh
              /bin/sed -e 's/api:5000/localhost:${toString cfg.hostPort}/' -e 's/listen\(.*\)80;/listen\1${toString cfg.hostPortFront};/' -i /etc/nginx/conf.d/default.conf
            ''}:/docker-entrypoint.d/99-zzz-edit-upstream.sh"
          ];
        };
      };
    };

    services.redis.servers.funkwhale = {
      enable = true;
      port = localVars.redisPort;
      requirePassFile = localVars.redisSecretFile;
    };

    services.postgresql = {
      enable = true;
      ensureDatabases = [ "funkwhale" ];
      ensureUsers = [
        {
          name = "funkwhale";
          ensurePermissions = { "DATABASE funkwhale" = "ALL PRIVILEGES"; };
        }
      ];
    };

    # Rest of postgresqlBackup in musi/backup.nix
    services.postgresqlBackup.databases = [ "funkwhale" ];

    # Reverse proxy configuration
    services.nginx.enable = true;
    services.nginx.virtualHosts."${cfg.domainName}" = {
      forceSSL = true;
      enableACME = true;
      root = localVars.frontendDir;
      locations = {
        "/" = {
          proxyPass = "http://localhost:${toString cfg.hostPortFront}";
          proxyWebsockets = true;
          extraConfig = ''
            client_max_body_size ${cfg.maxBodySize};
            # proxy_cookie_path / "/; Secure; HttpOnly; SameSite=strict";
          '';
        };
      };
      # TODO upgrade the security settings
      extraConfig = ''
        add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'wasm-unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; font-src 'self' data:; object-src 'none'; media-src 'self' data:";
        add_header Referrer-Policy "strict-origin-when-cross-origin";
      '';
    };

    systemd.services.funkwhale-scan = lib.mkIf cfg.autoScan.enable {
      serviceConfig = {
        Environment = [
          "BASE_URL=https://${cfg.domainName}/api/v1"
        ];
        EnvironmentFile = cfg.autoScan.passwordFile;
        ExecStart = pkgs.writeScript "funkwhale-scan" ''
          #!${pkgs.runtimeShell}
          set -e

          REQUEST=$(${pkgs.curl}/bin/curl -s --oauth2-bearer "$TOKEN" "$BASE_URL/federation/follows/library/all")
          LIBRARIES=$(echo $REQUEST | ${pkgs.jq}/bin/jq -r '.results[].library')
          COUNT=$(echo $REQUEST | ${pkgs.jq}/bin/jq -r '.count')

          echo "$COUNT libraries"
          for LIB in $LIBRARIES
          do
              printf "$LIB → "
              ${pkgs.curl}/bin/curl --no-progress-meter --oauth2-bearer "$TOKEN" -X POST "$BASE_URL/federation/libraries/$LIB/scan" | ${pkgs.jq}/bin/jq -r '.status'
          done
        '';
      };
      startAt = cfg.autoScan.startAt;
    };

  };
}
