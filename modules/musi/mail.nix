{ lib, config, pkgs, ... }:

let
  hostname = "mail.ppom.me";
  primaryDomain = "ppom.me";
  acmeDir = "/var/lib/acme/${hostname}";
  # TODO reference all ports in a centralized file
  autoconfigPort = "6548";
  autoconfigDomain = "autoconfig.ppom.me";
in
{
  # shared secret
  users.groups.postmaster = {};
  systemd.tmpfiles.rules = [
    "z /var/secrets/mail/postmaster 640 root postmaster - -"
  ];

  services.nginx.virtualHosts = {
    # Present in ./listmonk.nix
    # ${hostname} = {
    #   enableACME = true;
    #   forceSSL = true;
    #   locations."/".root = pkgs.writeTextDir "index.html" ''
    #     Here is the mail.
    #   '';
    # };
    "mta-sts.ppom.me" = {
      enableACME = true;
      forceSSL = true;
      locations."/.well-known/".root = pkgs.writeTextDir "mta-sts.txt" ''
        version: STSv1
        mode: enforce
        max_age: 604800
        mx: ${primaryDomain}
      '';
    };
    # Autoconfig steps were found here: https://nixos.wiki/wiki/Maddy
    # DNS entry: _autodiscover._tcp SRV 0 0 443 autoconfig
    ${autoconfigDomain} = {
      enableACME = true;
      forceSSL = true;
      locations."/".proxyPass = "http://localhost:${autoconfigPort}";
    };
  };

  services.go-autoconfig = {
    enable = true;
    settings = {
      service_addr = ":${autoconfigPort}";
      domain = autoconfigDomain;
      imap = {
        server = hostname;
        port = 993;
      };
      smtp = {
        server = hostname;
        port = 587;
      };
    };
  };

  users.users.maddy.extraGroups = [ config.security.acme.certs."${primaryDomain}".group ];


  networking.firewall.allowedTCPPorts = [
    25 # SMTP
    143 # IMAP, STARTTLS
    993 # IMAP, SSL/TLS
    587 # SMTP, STARTTLS
    465 # SMTP, SSL/TLS
  ];

  environment.etc."fail2ban/filter.d/maddy.conf".text = ''
    [INCLUDES]
    before = common.conf
    [Definition]
    failregex = ^.*authentication failed.*"src_ip":"<ADDR>:.*$
    ignoreregex =
    journalmatch = _SYSTEMD_UNIT=maddy.service + _COMM=maddy
  '';
  services.fail2ban.jails.maddy = ''
    enabled = true
    port = 25,143,993,587,465
    filter = maddy
    maxretry = 1
    findtime = 3600
    bantime = ${toString (3600 * 24 * 30)}
  '';


  # Restart maddy when a mail sending fails
  # Issue: https://github.com/foxcpp/maddy/issues/475
  environment.etc."fail2ban/filter.d/maddy-restart.conf".text = ''
    [INCLUDES]
    before = common.conf
    [Definition]
    failregex = ^.*queue: delivery attempt failed.*<ADDR>.*$
    journalmatch = _SYSTEMD_UNIT=maddy.service + _COMM=maddy
  '';
  environment.etc."fail2ban/action.d/maddy-restart.conf".text = ''
    [Definition]
    actionstart =
    actionstop =
    actioncheck =
    actionban = ${pkgs.systemd}/bin/systemctl restart maddy.service
    actionunban =
  '';
  services.fail2ban.jails.maddy-restart = ''
    enabled = true
    filter = maddy-restart
    action = maddy-restart
    maxretry = 1
    findtime = 40
    bantime = 40
  '';

  systemd.services.maddy = {
    after = [ "network.target" ];
    # restartTriggers = [ config.environment.etc."resolv.conf".source ];
  };

  systemd.services.restart-maddy = {
    script = ''
      ${pkgs.systemd}/bin/systemctl restart maddy.service
    '';
    startAt = "08:00";
  };

  services.maddy = {
    inherit primaryDomain hostname;
    enable = true;
    openFirewall = true;
    config = ''
      tls file ${acmeDir}/cert.pem ${acmeDir}/key.pem

      # Store accounts with sqlite
      auth.pass_table local_authdb {
          table sql_table {
              driver sqlite3
              dsn credentials.db
              table_name passwords
          }
      }

      # Store mails with sqlite
      storage.imapsql local_mailboxes {
          driver sqlite3
          dsn imapsql.db
      }

      table.chain local_rewrites {
          # Handle 'user+alias@domain' delivery to 'user@domain'
          # optional_step regexp "(.+)\+(.+)@(.+)" "$1@$3"
          # postmaster as a catchall address
          optional_step regexp "(.+)@(.+)" "postmaster@$2"
          optional_step static {
              entry postmaster postmaster@$(primary_domain)
          }
      }

      # Handle local domains
      msgpipeline local_routing {
          destination postmaster $(local_domains) {
              modify {
                  replace_rcpt &local_rewrites

                  # FIXME
                  # Postmaster as a catch-all address
                  # replace_rcpt regex ".*" "postmaster@$(primary_domain)"
              }
              deliver_to &local_mailboxes
          }
          # Should not happen
          default_destination {
              reject 550 5.1.1 "Who?"
          }
      }

      smtp tcp://0.0.0.0:25 {
          limits {
              all rate 10 1s
              all concurrency 10
          }

          dmarc yes
          check {
              require_mx_record
              dkim
              spf
          }

          source $(local_domains) {
              reject 501 5.1.8 "Use Submission for outgoing SMTP"
          }
          default_source {
              destination postmaster $(local_domains) {
                  deliver_to &local_routing
              }
              default_destination {
                  reject 550 5.1.1 "User doesn't exist"
              }
          }
      }

      submission tls://0.0.0.0:465 tcp://0.0.0.0:587 {
          limits {
              all rate 10 1s
          }
          auth &local_authdb
          source $(local_domains) {
              check {
                  authorize_sender {
                      prepare_email &local_rewrites
                      user_to_email identity
                  }
              }
              destination postmaster $(local_domains) {
                  deliver_to &local_routing
              }
              default_destination {
                  modify {
                      dkim $(primary_domain) $(local_domains) default
                  }
                  deliver_to &remote_queue
              }
          }
          default_source {
              reject 501 5.1.8 "Non-local sender domain"
          }
      }

      target.remote outbound_delivery {
          limits {
              destination rate 10 1s
              destination concurrency 10
          }
          mx_auth {
              # dane
              mtasts {
                  cache fs
                  fs_dir mtasts_cache/
              }
              local_policy {
                  min_tls_level encrypted
                  min_mx_level none
              }
          }
      }

      target.queue remote_queue {
          target &outbound_delivery
          autogenerated_msg_domain $(primary_domain)
          bounce {
              destination postmaster $(local_domains) {
                  deliver_to &local_routing
              }
              default_destination {
                  reject 550 5.0.0 "Refusing to send DSNs to non-local addresses"
              }
          }
      }

      imap tls://0.0.0.0:993 tcp://0.0.0.0:143 {
          auth &local_authdb
          storage &local_mailboxes
      }
    '';
  };
}
