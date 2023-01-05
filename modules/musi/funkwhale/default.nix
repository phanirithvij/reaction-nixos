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

    autoPlaylistImport = {
      enable = mkOption {
        type = bool;
        default = false;
        description = "enable regular import of playlists";
      };

      passwordFile = mkOption {
        type = str;
        description = mdDoc ''
          An env file containing the generated token in the user's settings.
          Needs permissions `read` and `write:playlists`.
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
          mkdir -p /var/lib/funkwhale/static
          chown funkwhale:funkwhale /var/lib/funkwhale /var/lib/funkwhale/static
          chmod 755 /var/lib/funkwhale /var/lib/funkwhale/static

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
    };

    virtualisation.oci-containers = {
      backend = "docker";

      containers = let
        commonOptions = {
          autoStart = true;
          image = "funkwhale/funkwhale:${cfg.funkwhaleVersion}";
          extraOptions = [ "--network" "host" ]; # to connect to postgresql
          environmentFiles = [ localVars.pythonSecretFile ];
          environment = pythonEnv;
          user = "${toString config.users.users.funkwhale.uid}:${toString config.users.groups.funkwhale.gid}";
        };
        commonVolumes = [
            "${cfg.musicDir}:/music:ro"
            "${cfg.mediaDir}:/${pythonEnv.MEDIA_ROOT}"
        ];
      in {
        funkwhale-celeryworker = commonOptions // {
          cmd = [ "celery" "-A" "funkwhale_api.taskapp" "worker" "-l" "INFO" "--concurrency=8" ];
          volumes = commonVolumes;
        };

        funkwhale-celerybeat = commonOptions // {
          cmd = [ "celery" "-A" "funkwhale_api.taskapp" "beat" "--pidfile=" "-l" "INFO" "-s" "/tmp/celerybeat-schedule" ];
        };

        funkwhale-api = commonOptions // {
          volumes = commonVolumes ++ [
            "${localVars.frontendDir}:/frontend"
            "${localVars.staticDir}:${pythonEnv.STATIC_ROOT}"
            "${./merge-funkwhale-artists.py}:/app/merge-funkwhale-artists.py:ro"
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
      locations = let
        frontConfigs = ''
          add_header Content-Security-Policy "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; font-src 'self' data:; object-src 'none'; media-src 'self' data:";
          add_header Referrer-Policy "strict-origin-when-cross-origin";
          add_header Service-Worker-Allowed "/";
          add_header X-Frame-Options "DENY";
          add_header Pragma public;
          add_header Cache-Control "public, must-revalidate, proxy-revalidate";
          expires 30d;
        '';
        proxyBackConfigs = ''
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $http_x_forwarded_proto;
          proxy_set_header X-Forwarded-Host $http_x_forwarded_host;
          proxy_set_header X-Forwarded-Port $http_x_forwarded_port;
          proxy_redirect off;
          # websocket support
          proxy_http_version 1.1;
          proxy_set_header Upgrade $http_upgrade;
          proxy_set_header Connection $connection_upgrade;
          proxy_cookie_path / "/; Secure; HttpOnly; SameSite=strict";
        '';
        proxyUrl = "http://localhost:${toString cfg.hostPort}";
      in {
        "/" = {
          proxyWebsockets = true;
          proxyPass = proxyUrl;
          extraConfig = ''
            proxy_set_header X-Forwarded-Port $http_x_forwarded_port;
            proxy_redirect off;
            proxy_cookie_path / "/; Secure; SameSite=strict";
            client_max_body_size ${cfg.maxBodySize};
          '';
        };
        "/front/" = {
          alias = "${localVars.frontendDir}/";
          extraConfig = frontConfigs;
        };
        "=/front/embed.html" = {
          alias = "${localVars.frontendDir}/embed.html";
          extraConfig = frontConfigs;
        };
        "/federation/" = {
          extraConfig = ''
            proxy_pass   ${proxyUrl}/federation/;
          '' + proxyBackConfigs;
        };
        "/rest/" = {
          extraConfig = ''
            proxy_pass   ${proxyUrl}/api/subsonic/rest/;
          '' + proxyBackConfigs;
        };
        "/.well-known/" = {
          extraConfig = ''
            proxy_pass   ${proxyUrl}/.well-known/;
          '' + proxyBackConfigs;
        };
        "/media/" = {
          alias = "${cfg.mediaDir}/";
        };
        # TODO check the log on these paths to be sure it's really used
        "/_protected/media/" = {
          extraConfig = "internal;";
          alias = "${cfg.mediaDir}/";
        };
        "/_protected/music/" = {
          extraConfig = "internal;";
          alias = "${cfg.musicDir}/";
        };
        "/staticfiles/" = {
          alias = "${localVars.staticDir}/";
        };
      };
      # TODO upgrade the security settings
      extraConfig = ''
        add_header Content-Security-Policy "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; font-src 'self' data:; object-src 'none'; media-src 'self' data:";
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

    systemd.services.funkwhale-playlist-import = lib.mkIf cfg.autoPlaylistImport.enable {
      serviceConfig = {
        Environment = [
          "INSTANCE_URL=https://${cfg.domainName}"
        ];
        EnvironmentFile = cfg.autoPlaylistImport.passwordFile;
        ExecStart = let
          python = pkgs.python3.withPackages (ps: with ps; [ requests rapidfuzz ]);
        in pkgs.writeScript "funkwhale-playlist-import" ''
          #!${pkgs.runtimeShell}
          set -e
          cd /var/lib/funkwhale-playlist-import
          [ -e ./funkwhale-playlist-import ] || ${pkgs.git}/bin/git clone https://framagit.org/ppom/funkwhale-playlist-import funkwhale-playlist-import
          cd ./funkwhale-playlist-import
          ${pkgs.git}/bin/git pull
          if [ ! -e ./secrets ]
          then
            mkdir ./secrets
            echo "$INSTANCE_URL" > ./secrets/instance_url
            echo "$TOKEN" > ./secrets/token
          fi
          for file in ./lists/*
          do
            ${python}/bin/python import-from-txt.py "$file"
          done
        '';
        DynamicUser = true;
        StateDirectory = "funkwhale-playlist-import";
      };
      startAt = cfg.autoPlaylistImport.startAt;
    };
  };
}
