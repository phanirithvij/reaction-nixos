{ lib, config, pkgs, ... }:

let
  ecomailAddress = "paco@ecomail.io";
  personnalAddress = "paco@ppom.me";
  adminAddress = "admin@ppom.me";
  poubelleAddress = "poubelle@ppom.me";
in
{
  imports = [
    (builtins.fetchTarball {
      # Pick a commit from the branch you are interested in
      url = "https://gitlab.com/simple-nixos-mailserver/nixos-mailserver/-/archive/f535d8123c4761b2ed8138f3d202ea710a334a1d/nixos-mailserver-f535d8123c4761b2ed8138f3d202ea710a334a1d.tar.gz";
      # And set its hash
      sha256 = "sha256:0csx2i8p7gbis0n5aqpm57z5f9cd8n9yabq04bg1h4mkfcf7mpl6";
    })
  ];

  mailserver = {
    enable = true;
    fqdn = "mail.ppom.me";
    domains = [ "ppom.me" ];

    # A list of all login accounts. To create the password hashes, use
    # nix run nixpkgs.apacheHttpd -c htpasswd -nbB "" "super secret password" | cut -d: -f2
    loginAccounts = {
      # Me
      "${personnalAddress}" = {
        hashedPasswordFile = "/var/secrets/mail/paco.secret";
        quota = "3G";
      };
      # Send only
      "no-reply@ppom.me" = {
        hashedPasswordFile = "/var/secrets/mail/no-reply.secret";
        sendOnly = true;
      };
      # Official one
      "${adminAddress}" = {
        hashedPasswordFile = "/var/secrets/mail/admin.secret";
        aliases = ["abuse@ppom.me" "postmaster@ppom.me"];
        quota = "2G";
      };
      # Catch all
      "${poubelleAddress}" = {
        hashedPasswordFile = "/var/secrets/mail/poubelle.secret";
        catchAll = [ "ppom.me" ];
        quota = "2G";
      };
      # People
      "lzn@ppom.me" = {
        hashedPasswordFile = "/var/secrets/mail/lzn.secret";
        quota = "2G";
      };
    };

    forwards = {
      "${personnalAddress}" = poubelleAddress;
      "${adminAddress}" = poubelleAddress;
    };

    # Use Let's Encrypt certificates. Adds a virtual host to nginx.
    certificateScheme = 3;
  };

  systemd.services.postfix.enable = lib.mkForce false;
}
