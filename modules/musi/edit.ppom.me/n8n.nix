{ lib, config, pkgs, ... }:
let
  common = import ./common.nix {};
in {
  services.n8n = {
    enable = true;
    settings = {
      path = "/n8n/";
      protocol = "http";
      port = 5678;
      listen_address = "127.0.0.1";
      # proxy_hops = 1; # TODO for 24.05: for now it's not an option
      editorBaseUrl = "https://edit.ppom.me/n8n/";
      userManagement.emails.smtp = {
        host = "smtp.ecomail.fr";
        auth.user = "paco@ecomail.io";
        # password in env below
      };
      hideUsagePage = true;
      versionNotifications.enabled = false;
      hiringBanner.enabled = false;
      ai.enabled = false;
    };
  };

  systemd.services.n8n = {
    serviceConfig.LoadCredential = [
      "smtp_pass:/var/secrets/mail/ecomail"
      "ssh_key:${common.sshKey}"
    ];
    environment = {
      "N8N_SMTP_PASS_FILE" = "/run/credentials/n8n.service/smtp_pass";
      # "VUE_APP_URL_BASE_API" = "";
    };
    path = with pkgs; [ git zola rsync openssh ];
  };

  nixpkgs.config.allowlistedLicenses = with lib.licenses; [ sustainableUse ];

  services.nginx.virtualHosts = {
    "edit.ppom.me" = {
      locations = {
        "/n8n/" = {
          proxyPass = "http://127.0.0.1:${toString config.services.n8n.settings.port}/";
          proxyWebsockets = true;
        };
      };
    };
  };
}
