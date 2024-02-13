{ lib, config, pkgs, ... }:
let
  unstable = import <nixos-unstable> {};
in {
  services.mobilizon = {
    enable = true;
    package = unstable.pkgs.mobilizon.overrideAttrs (final: previous: {
      src = /home/ao/prg/sources/mobilizon;
    });
    settings = let
      # These are helper functions, that allow us to use all the features of the Mix configuration language.
      # - mkAtom and mkRaw both produce "raw" strings, which are not enclosed by quotes.
      # - mkGetEnv allows for convenient calls to System.get_env/2
      inherit ((pkgs.formats.elixirConf { }).lib) mkAtom mkRaw mkGetEnv;
      email = "ppom@localhost";
    in {
      ":mobilizon" = {

        # General information about the instance
        ":instance" = {
          name = "My mobilizon instance";
          description = "A descriptive text that is going to be shown on the start page.";
          hostname = "localhost";
          email_from = email;
          email_reply_to = email;
        };

        # SMTP configuration
        "Mobilizon.Web.Email.Mailer" = {
          adapter = mkAtom "Swoosh.Adapters.SMTP";
          relay = "localhost";
          # usually 25, 465 or 587
          port = 587;
          username = email;
          # See "Providing a SMTP password" below
          password = mkGetEnv { envVariable = "SMTP_PASSWORD"; };
          tls = mkAtom ":never";
          allowed_tls_versions = [
            (mkAtom '':tlsv1'')
            (mkAtom '':"tlsv1.1"'')
            (mkAtom '':"tlsv1.2"'')
          ];
          retries = 1;
          no_mx_lookups = false;
          auth = mkAtom ":always";
        };

        "Mobilizon.Storage.Repo" = {
          username = "mobilizon";
          database = "mobilizon";
        };

      };
    };
  };

  services.nginx.virtualHosts.localhost = {
    enableACME = false;
    forceSSL = false;
  };

  systemd.services = let
    mobiservice = lib.mkForce [ "mobilizon.service" ];
  in {
    mobilizon.wantedBy = lib.mkForce [];
    nginx.wantedBy = mobiservice;
    nginx.before = mobiservice;
    postgresql.wantedBy = mobiservice;
    postgresql.before = mobiservice;
  };

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_15;
  };
}
