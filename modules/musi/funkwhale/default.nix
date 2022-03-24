# Create & network to reach host                            ↓ host ip on the network
# docker network create -d bridge --subnet 192.168.0.0/24 --gateway 192.168.0.1 mynet
# containers on this network will access to the host, for example to connect to a database
{ lib, pkgs, config, ... }:
with lib;
{
  options.services.funkwhale = {
    enable = mkEnableOption "enable Funkwhale using docker-compose";

    domainName = mkOption {
      type = types.str;
      description = "Domain you want to use";
    };

    funkwhaleVersion = mkOption {
      type = types.str;
      description = "Funkwhale version on Docker hub";
    };

    # TODO fix this. the option doesn't work, i didn't manage to change the port number (always 5000)
    hostPort = mkOption {
      type = types.int;
      description = "Port to expose on the host";
      default = 5000;
    };

    musicDir = mkOption {
      type = types.str;
      description = "Path to your music directory";
    };

    dataDir = mkOption {
      type = types.str;
      description = "Path to the data directory. Can also be a docker volume";
      default = "funkwhale_data";
    };

    maxBodySize = mkOption {
      type = types.str;
      description = "Max upload size. Handled by nginx";
      default = "100M";
    };

    # TODO rename options (not a cron)
    # TODO add systemd time option
    importCronEnable = mkEnableOption "Enable a daily job to update the library from disk";

    importCronLibraryID = mkOption {
      type = types.str;
      description = "ID of the library to import to";
    };
  };

  config = let
    cfg = config.services.funkwhale;
    localVars = {
      redisPort = 8325;
      redisSecretFile = "/var/lib/funkwhale/secrets/redis.secret";
      postgresSecretFile = "/var/lib/funkwhale/secrets/postgres.secret";
      pythonSecretFile = "/var/lib/funkwhale/secrets/env.secret";
      # filled by the API container, served by host NGINX
      frontendPath = "/var/lib/funkwhale/frontend";
    };
    composeGeneration = import ./docker-compose.nix;
    mediaDir = "${cfg.dataDir}/media";
    staticDir = "${cfg.dataDir}/static";
  in mkIf cfg.enable {
    # TODO make assertion on cron import

    # docker-compose generation
    environment.etc."generated/funkwhale/docker-compose.yml".source = (composeGeneration {
      toYaml = pkgs.toYaml;
      cfg = cfg // {
        inherit mediaDir staticDir;
        inherit (localVars) pythonSecretFile frontendPath;
      };
    });

    # TODO downgrade the containers user to funkwhale.
    # Even celery tells it shouldn't run as root!
    users = {
      users.funkwhale = {
        isSystemUser = true;
        packages = with pkgs; [];
        group = "funkwhale";
      };
      groups.funkwhale = {};
    };

    systemd.services.funkwhale-init = {
      enable = true;
      description = "Secret generation for Funkwhale";
      wantedBy = [ "multi-user.target" ];
      before = [ "redis.service" "postgresql.service" ];
      serviceConfig = {
        Type = "oneshot";
        User = "root";
      };
      path = [ pkgs.libressl ];
      # TODO reload redis?
      script = with localVars; ''
        genPasswd() {
          # tr -cd '[:alnum:]' < /dev/urandom | fold -w30 | head -n1
          openssl rand -base64 32 | tr -cd '[:alnum:]'
        }
        if test '!' -f ${localVars.pythonSecretFile}
        then
          echo Generating secrets…
          REDIS_PASSWORD=$(genPasswd)
          POSTGRES_PASSWORD=$(genPasswd)
          DJANGO_PASSWORD=$(genPasswd)
          mkdir -p $(dirname ${redisSecretFile})
          mkdir -p $(dirname ${postgresSecretFile})
          mkdir -p $(dirname ${pythonSecretFile})
          touch ${redisSecretFile} ${postgresSecretFile} ${pythonSecretFile}
          chmod 640 ${redisSecretFile} ${postgresSecretFile} ${pythonSecretFile}
          chown root:funkwhale ${pythonSecretFile}
          chown root:redis ${redisSecretFile}
          chown root:postgres ${postgresSecretFile}

          echo $REDIS_PASSWORD > ${redisSecretFile}
          echo $POSTGRES_PASSWORD > ${postgresSecretFile}
          cat > ${pythonSecretFile} <<EOF
        CACHE_URL=redis://:$REDIS_PASSWORD@localhost:${builtins.toString redisPort}/0
        DJANGO_SECRET_KEY=$DJANGO_PASSWORD
        DATABASE_URL=postgresql://root:$POSTGRES_PASSWORD@localhost:${builtins.toString config.services.postgresql.port}/funkwhale
        EOF
        fi
        '';
    };

    # TODO fix permission issues:
    # - Switch to password authentication (not based on system user)
    # - Downgrade the role. For now the root role is used and is a postgresql superuser.
    systemd.services.funkwhale-postgres-password = {
      enable = true;
      description = "Secret generation for Funkwhale, part 2";
      wantedBy = [ "multi-user.target" ];
      requires = [ "postgresql.service" "funkwhale-init.service" ];
      after = [ "postgresql.service" "funkwhale-init.service" ];
      serviceConfig = {
        Type = "oneshot";
        User = "postgres";
      };
      path = [ pkgs.postgresql ];
      script = with localVars; ''
        POSTGRES_PASSWORD=$(cat ${postgresSecretFile})
        psql -c "ALTER USER funkwhale WITH PASSWORD '$POSTGRES_PASSWORD';"
        psql -c "ALTER USER root      WITH PASSWORD '$POSTGRES_PASSWORD';"
        psql funkwhale -c "CREATE EXTENSION IF NOT EXISTS 'unaccent';"
        psql funkwhale -c "CREATE EXTENSION IF NOT EXISTS 'citext';"

        '';
    };
    
    services.redis = {
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
        {
          name = "root";
          ensurePermissions = { "DATABASE funkwhale" = "ALL PRIVILEGES"; };
        }
      ];
      identMap = ''
        funkwhale root funkwhale
        funkwhale funkwhale funkwhale
      '';
    };

    # Reverse proxy configuration
    services.nginx.enable = true;
    services.nginx.virtualHosts."${cfg.domainName}" = {
      forceSSL = true;
      enableACME = true;
      root = localVars.frontendPath;
      locations = let
        frontConfigs = ''
          add_header Content-Security-Policy "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; font-src 'self' data:; object-src 'none'; media-src 'self' data:";
          add_header Referrer-Policy "strict-origin-when-cross-origin";
          add_header Service-Worker-Allowed "/";
          add_header X-Frame-Options "ALLOW";
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
        '';
        proxyUrl = "http://localhost:${builtins.toString cfg.hostPort}";
      in {
        "/" = {
          proxyWebsockets = true;
          proxyPass = proxyUrl;
          extraConfig = ''
            proxy_set_header X-Forwarded-Port $server_port;
            proxy_redirect off;
            client_max_body_size ${cfg.maxBodySize};
          '';
        };
        "/front/" = {
          alias = "${localVars.frontendPath}/";
          extraConfig = frontConfigs;
        };
        "=/front/embed.html" = {
          alias = "${localVars.frontendPath}/embed.html";
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
          alias = "${mediaDir}/";
        };
        # TODO check the log on these paths to be sure it's really used
        "/_protected/media/" = {
          extraConfig = "internal;";
          alias = "${mediaDir}/";
        };
        "/_protected/music/" = {
          extraConfig = "internal;";
          alias = "${cfg.musicDir}/";
        };
        "/staticfiles/" = {
          alias = "${staticDir}/";
        };
      };
      # TODO upgrade the security settings
      extraConfig = ''
        add_header Content-Security-Policy "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; font-src 'self' data:; object-src 'none'; media-src 'self' data:";
        add_header Referrer-Policy "strict-origin-when-cross-origin";
      '';
    };
  };
}
