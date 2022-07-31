{
  toYaml
  , cfg
  , celeryConcurrency ? 8
}:
let
  pythonEnv = {
    # We're in production lol
    DJANGO_SETTINGS_MODULE = "config.settings.production";
    # Error reporting
    # RAVEN_ENABLED = "true";
    # RAVEN_DSN = "https://44332e9fdd3d42879c7d35bf8562c6a4:0062dc16a22b41679cd5765e5342f716@sentry.eliotberriot.com/5";
    # Basic shit
    FUNKWHALE_HOSTNAME = cfg.domainName;
    FUNKWHALE_PROTOCOL = "https";
    FUNKWHALE_API_IP = "127.0.0.1";
    FUNKWHALE_API_PORT = cfg.hostPort;
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
in toYaml "docker-compose" {
  version = "3";

  services = {

    celeryworker = {
      restart = "unless-stopped";
      image = "funkwhale/funkwhale:${cfg.funkwhaleVersion}";
      network_mode = "host";
      env_file = [ cfg.pythonSecretFile ];
      command = "celery -A funkwhale_api.taskapp worker -l INFO --concurrency=${builtins.toString celeryConcurrency}";
      environment = {
        C_FORCE_ROOT = "true";
      } // pythonEnv;
      volumes = [
        "${cfg.musicDir}:/music:ro"
        "${cfg.mediaDir}:/${pythonEnv.MEDIA_ROOT}"
      ];
    };

    celerybeat = {
      restart = "unless-stopped";
      image = "funkwhale/funkwhale:${cfg.funkwhaleVersion}";
      network_mode = "host";
      env_file = [ cfg.pythonSecretFile ];
      environment = pythonEnv;
      command = "celery -A funkwhale_api.taskapp beat --pidfile= -l INFO";
    };

    api = {
      restart = "unless-stopped";
      image = "funkwhale/funkwhale:${cfg.funkwhaleVersion}";
      network_mode = "host";
      env_file = [ cfg.pythonSecretFile ];
      environment = pythonEnv;
      volumes = [
        "${cfg.musicDir}:/music:ro"
        "${cfg.mediaDir}:/${pythonEnv.MEDIA_ROOT}"
        "${cfg.staticDir}:${pythonEnv.STATIC_ROOT}"
        "${cfg.frontendPath}:/frontend"
        "./merge-funkwhale-artists.py:/app/merge-funkwhale-artists.py:ro"
      ];
    };
  };
}
