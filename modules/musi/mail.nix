{ lib, config, pkgs, ... }:
{
  # shared secret
  users.groups.postmaster = {};
  systemd.tmpfiles.rules = [
    "z /var/secrets/mail/postmaster 640 root postmaster - -"
  ];
}
