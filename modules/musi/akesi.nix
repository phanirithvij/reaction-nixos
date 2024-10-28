{ config, lib, pkgs, ... }:
let
  port = 58234;
  ip = "10.1.1.2";
  akesiIp = "10.1.1.1";
in {
  services.nfs.server = {
    enable = true;
    # Doc: https://www.man7.org/linux/man-pages/man5/exports.5.html
    exports = ''
      /data/akesi ${akesiIp}(${lib.concatStringsSep "," [
        # Allow writes
        "rw"
        # Strong consistency
        "sync"
        # Docs says it causes more problems than solutions
        "no_subtree_check"
        # All requests are set to the following UID/GID
        "all_squash"
        "anonuid=${toString config.users.users."nfsakesi".uid}"
        "anongid=${toString config.users.groups."nfsakesi".gid}"
      ]})
    '';
    hostName = ip;
  };

  users.users.nfsakesi = {
    uid = 70;
    group = "nfsakesi";
  };
  users.groups.nfsakesi.gid = 70;

  environment.systemPackages = [ pkgs.wireguard-tools ];
  networking = {
    firewall = {
      # Only allow akesi to connect to the NFS server via its Wireguard IP
      # Accept both udp and tcp
      extraCommands = ''
        iptables -A nixos-fw -p udp --dport 2049 -s ${akesiIp} -j nixos-fw-accept
        iptables -A nixos-fw -p tcp --dport 2049 -s ${akesiIp} -j nixos-fw-accept
      '';
      allowedUDPPorts = [ port ];
    };
    wg-quick.interfaces.nasin = {
      address = [ "${ip}/32" ];
      privateKeyFile = "/var/secrets/nasin.key";
      listenPort = port;
      peers = [
        {
          endpoint = "akesi.ppom.me:${toString port}";
          publicKey = "rJ91zWvjJwj5ByxLx1tiyiRR3m8qRmZ4sQm7RctSTlc=";
          allowedIPs = [ "${akesiIp}/32" ];
        }
      ];
    };
  };

  services.reaction.settings.patterns.ip.ignore = [ akesiIp ];
}
