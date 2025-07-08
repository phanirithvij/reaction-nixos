# Create & network to reach host                            ↓ host ip on the network
# docker network create -d bridge --subnet 192.168.0.0/24 --gateway 192.168.0.1 mynet
# containers on this network will access to the host, for example to connect to a database
{ lib, pkgs, config, ... }:
{
  options.services.funkwhale2 = with lib; with types; {
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
      default = 5001;
    };

    hostPortFront = mkOption {
      type = int;
      description = "Port to expose on the host for the frontend";
      default = 4998;
    };

    musicDir = mkOption {
      type = str;
      description = "Path to your music directory";
    };

    mediaDir = mkOption {
      type = str;
      description = "Path to the data directory";
      default = "/var/lib/funkwhale2/media";
    };

    maxBodySize = mkOption {
      type = str;
      description = "Max upload size. Handled by nginx";
      default = "100M";
    };

    enableLocalTypesense = mkEnableOption ''
      Enable a local Typesense server for search.
      If you don't set yourself `services.typesense.apiKeyFile`, it will be set to `/var/secrets/typesense/apikey`.
      If the path doesn't exist, a random secret will be generated.
    '';

    autoScan = {
      enable = mkEnableOption "enable regular scan of subscribed libraries";

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
    cfg = config.services.funkwhale2;

    localVars = let 
      secretsDir = "/var/lib/funkwhale2/secrets";
    in {
      redisPort = 8326;
      inherit secretsDir;
      redisSecretFile = "${secretsDir}/redis.secret";
      pythonSecretFile = "${secretsDir}/env.secret";
      # filled by the API container, served by host NGINX
      frontendDir = "/var/lib/funkwhale2/frontend";
      staticDir = "/var/lib/funkwhale2/static";
      apiKeyFile = config.services.typesense.apiKeyFile;
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
      EXTERNAL_REQUESTS_TIMEOUT = "120";
    } // lib.optionalAttrs cfg.enableLocalTypesense {
      TYPESENSE_HOST = "localhost";
    };

    dockerServiceOverrides = {
      after = [ "funkwhale2-init.service" ];
      requires = [ "funkwhale2-init.service" ];
    };

  in lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.autoScan.enable -> (cfg.autoScan.passwordFile != null && cfg.autoScan.startAt != null);
        message = "if you enable autoScan, you must set its parameters";
      }
    ];

    users = {
      users.funkwhale2 = {
        isSystemUser = true;
        group = "funkwhale2";
      };
      groups.funkwhale2 = {};
    };

    systemd.tmpfiles.rules = [
      "d ${localVars.secretsDir} 755 root root - -"
      "d /var/lib/funkwhale2 755 funkwhale2 funkwhale2 - -"
      "d ${localVars.staticDir} 755 funkwhale2 funkwhale2 - -"
      "Z ${localVars.staticDir} 755 funkwhale2 funkwhale2 - -"
    ];

    systemd.services = {
      funkwhale2-init = {
        enable = true;
        description = "Secret generation for Funkwhale2";
        wantedBy = [ "multi-user.target" ];
        after = [ "postgresql.service" ];
        before = [ "redis-funkwhale2.service" ] ++ lib.optionals cfg.enableLocalTypesense [ "typesense.service" ];
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
            touch ${redisSecretFile} ${pythonSecretFile}
            chmod 640 ${redisSecretFile} ${pythonSecretFile}
            chown root:funkwhale2 ${pythonSecretFile}
            chown root:redis-funkwhale2 ${redisSecretFile}

            /run/wrappers/bin/sudo -u postgres \
              psql -c "ALTER USER funkwhale2 WITH PASSWORD '$POSTGRES_PASSWORD';"

            echo "$REDIS_PASSWORD" > ${redisSecretFile}
            cat > ${pythonSecretFile} <<EOF
          CACHE_URL=redis://:$REDIS_PASSWORD@localhost:${toString redisPort}/0
          DJANGO_SECRET_KEY=$DJANGO_PASSWORD
          DATABASE_URL=postgresql://funkwhale2:$POSTGRES_PASSWORD@localhost:${toString config.services.postgresql.settings.port}/funkwhale2
          EOF
          fi

          ${lib.optionalString cfg.enableLocalTypesense ''
          if test '!' -f "${apiKeyFile}"
          then
            echo Generating Typesense API key...
            TYPESENSE_PASSWORD=$(genPasswd)
            mkdir -p "$(dirname "${apiKeyFile}")"
            echo $TYPESENSE_PASSWORD > "${apiKeyFile}"
            chmod 640 "${apiKeyFile}"
            chown root:typesense "${apiKeyFile}"
          fi
          # This is done everytime in case a human changes the secret. Better to have a SSOT.
          sed -i -e '/TYPESENSE_API_KEY/d' \
                 -e '$'"aTYPESENSE_API_KEY=$(cat "${apiKeyFile}")" \
                 ${pythonSecretFile}
          ''}
        '';
      };

      docker-funkwhale2-api = dockerServiceOverrides;
      docker-funkwhale2-celeryworker = dockerServiceOverrides;
      docker-funkwhale2-celerybeat = dockerServiceOverrides;
      docker-funkwhale2-front = {
        after = [ "docker-funkwhale2-api.service" ];
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
          user = "${toString config.users.users.funkwhale2.uid}:${toString config.users.groups.funkwhale2.gid}";
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
        funkwhale2-celeryworker = pythonOptions // {
          cmd = [ "celery" "-A" "funkwhale_api.taskapp" "worker" "-l" "INFO" "--concurrency=8" ];
          volumes = mediaVolumes;
        };

        funkwhale2-celerybeat = pythonOptions // {
          cmd = [ "celery" "-A" "funkwhale_api.taskapp" "beat" "--pidfile=" "-l" "INFO" "-s" "/tmp/celerybeat-schedule" ];
        };

        funkwhale2-api = pythonOptions // {
          volumes = mediaVolumes ++ codeVolumes ++ [
            "${./merge-funkwhale-albums.py}:/app/merge-funkwhale-albums.py:ro"
            "${./merge-funkwhale-artists.py}:/app/merge-funkwhale-artists.py:ro"
            "${./merge-funkwhale-tracks.py}:/app/merge-funkwhale-tracks.py:ro"
            "${pkgs.writeShellScript "merge.sh" ''
              case "$1" in
                tracks|track)
                  TRACK1="$2" TRACK2="$3" python merge-funkwhale-tracks.py ;;
                artists|artist)
                  ARTIST1="$2" ARTIST2="$3" python merge-funkwhale-artists.py ;;
                albums|album)
                  ALBUM1="$2" ALBUM2="$3" python merge-funkwhale-albums.py ;;
                *)
                  print "merge album|artist|track id1 id2 (id1 <--merge into-- id2)"
              esac
            ''}:/usr/local/bin/merge:ro"
          ];
        };

        funkwhale2-front = basicOptions // {
          volumes = mediaVolumes ++ codeVolumes ++ [
            # FIXME this fix should not be necessary in 1.3.3
            "${pkgs.writeScript "edit-upstream" ''
              #!/bin/sh
              # Add this missing conf before when templates are evaluated in 20
              # See https://github.com/nginxinc/docker-nginx/tree/2879b26c7dedf1d958b1894a5c1b1dec3c026369/entrypoint
              /bin/sed \
                  -e '$ilocation /staticfiles/ { alias ''${STATIC_ROOT}/; add_header Access-Control-Allow-Origin '"'"'*'"'"'; }' \
                  -i /etc/nginx/templates/default.conf.template
            ''}:/docker-entrypoint.d/19-edit-upstream.sh"
            # FIXME this fix should not be necessary in 1.3.3
            # See how to use upstream env substitution
            "${pkgs.writeScript "edit-upstream" ''
              #!/bin/sh
              # Change the generated conf at the last moment (after 99)
              /bin/sed \
                  -e 's/api:5000/localhost:${toString cfg.hostPort}/' \
                  -e 's/listen\(.*\)80;/listen\1${toString cfg.hostPortFront};/' \
                  -i /etc/nginx/conf.d/default.conf
            ''}:/docker-entrypoint.d/99-zzz-edit-upstream.sh"
          ];
        };
      };
    };

    services.redis.servers.funkwhale2 = {
      enable = true;
      port = localVars.redisPort;
      requirePassFile = localVars.redisSecretFile;
    };

    services.postgresql = {
      enable = true;
      ensureDatabases = [ "funkwhale2" ];
      ensureUsers = [{
        name = "funkwhale2";
        ensureDBOwnership = true;
      }];
    };

    # Rest of postgresqlBackup in musi/backup.nix
    services.postgresqlBackup.databases = [ "funkwhale2" ];

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

    systemd.services.funkwhale2-scan = lib.mkIf cfg.autoScan.enable {
      serviceConfig = {
        Environment = [
          "BASE_URL=https://${cfg.domainName}/api/v1"
        ];
        EnvironmentFile = cfg.autoScan.passwordFile;
        ExecStart = pkgs.writeShellScript "funkwhale2-scan" ''
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

    services.typesense = lib.mkIf cfg.enableLocalTypesense {
      enable = true;
      apiKeyFile = lib.mkDefault "/var/secrets/typesense/apikey";
      settings.server.api-address = lib.mkDefault "127.0.0.1";
    };
    systemd.services.typesense.serviceConfig = lib.mkIf cfg.enableLocalTypesense {
      DynamicUser = lib.mkForce false;
    };
    users.users.typesense = lib.mkIf cfg.enableLocalTypesense {
      isSystemUser = true;
      group = "typesense";
    };
    users.groups.typesense = lib.mkIf cfg.enableLocalTypesense {};
  };
}
