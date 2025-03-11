{ ... }: let
  base = "/var/lib/ntfy-sh";
in {
  services.ntfy-sh = {
    enable = true;
    settings = {
      base-url = "https://notifs.ppom.me";
      listen-http = "127.0.0.1:8097";
      behind-proxy = true;
      # Storage
      cache-file = "${base}/cache.db";
      cache-duration = "7d";
      attachment-cache-dir = "${base}/attachments";
      attachment-expiry-duration = "7d";
      manager-interval = "1h";
      # ACL
      enable-login = true;
      auth-file = "${base}/user.db";
      auth-default-access = "deny-all";
    };
  };

  services.nginx.virtualHosts."notifs.ppom.me" = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://localhost:8097";
      proxyWebsockets = true;
    };
  };
}
