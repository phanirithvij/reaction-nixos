{ config, pkgs, ... }:

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
      url = "https://gitlab.com/simple-nixos-mailserver/nixos-mailserver/-/archive/5675b122a947b40e551438df6a623efad19fd2e7/nixos-mailserver-5675b122a947b40e551438df6a623efad19fd2e7.tar.gz";
      # And set its hash
      sha256 = "1fwhb7a5v9c98nzhf3dyqf3a5ianqh7k50zizj8v5nmj3blxw4pi";
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
}
