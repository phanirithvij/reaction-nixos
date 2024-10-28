{ config, lib, ... }:
let
  hostName = config.networking.hostName;
  hosts = builtins.fromTOML (builtins.readFile ./hosts.toml);
  host = hosts.${hostName};
in {
  services.nfs.server = {
    enable = true;
    # Doc: https://www.man7.org/linux/man-pages/man5/exports.5.html
    exports = ''
      /data/akesi ${hosts.akesi.address}(${lib.concatStringsSep "," [
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
    hostName = host.address;
  };

  users.users.nfsakesi = {
    uid = 70;
    group = "nfsakesi";
  };
  users.groups.nfsakesi.gid = 70;

  # Only allow akesi to connect to the NFS server via its Wireguard IP
  # Accept both udp and tcp
  networking.firewall.extraCommands = ''
    iptables -A nixos-fw -p udp --dport 2049 -s ${hosts.akesi.address} -j nixos-fw-accept
    iptables -A nixos-fw -p tcp --dport 2049 -s ${hosts.akesi.address} -j nixos-fw-accept
  '';

  services.reaction.settings.patterns.ip.ignore = [ hosts.akesi.address ];
}
