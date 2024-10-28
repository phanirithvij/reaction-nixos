{ lib, config, pkgs, ... }:
let
  hostName = config.networking.hostName;
  hosts = builtins.fromTOML (builtins.readFile ../common/hosts.toml);
  host = hosts.${hostName};
  mountName = "musi";
  mountPath = "/${mountName}";
in lib.mkMerge [
  # NFS
  {
    services.nfs.server.enable = true;
    environment.systemPackages = [ pkgs.nfs-utils ];
    boot.kernelModules = [ "nfs" ];
    systemd.mounts = [
      {
        type = "nfs";
        what = "${hosts.musi.address}:/data/akesi";
        where = mountPath;
      }
    ];
  }
  # Transmission
  {
    systemd.services.transmission = {
      after = [ "${mountName}.mount" ];
      requires = [ "${mountName}.mount" ];
    };
    services.transmission = {
      enable = true;
      openPeerPorts = true;
      performanceNetParameters = true;
      # credentialsFile = "/var/secrets/transmission/auth.json";
      settings = {
        incomplete-dir = "${mountPath}/downloading";
        download-dir = "${mountPath}/upload-here";
        watch-dir = "${mountPath}/dot.torrents";
        watch-dir-enabled = true;
        speed-limit-up = 2 * 1024; # KB/s
        speed-limit-up-enabled = true;
        rpc-bind-address = host.address;
        rpc-username = "ppom";
        rpc_authentication_required = false;
      };
    };

    networking.firewall.extraCommands = ''
      iptables -A nixos-fw -p udp --dport 9091 -s ${hosts.sona.address}/24 -j nixos-fw-accept
    '';

    environment.systemPackages = [
      # pkgs.stig # currently broken
    ];

    # stig currenlty broken
    # systemd.services.stig-status = {
    #   description = "Print transmission status to a file available to akesi@anpa";
    #   script = "LINES=35 COLUMNS=120 ${pkgs.stig}/bin/stig ls > /musi/stig-output || true";
    #   serviceConfig.User = "transmission";
    #   startAt = "*:*:0,30";
    # };

    systemd.services.new-torrent-watch = {
      description = "Touch new files not seen by transmission's inotify because /musi is a network fs";
      script = ''
        ${pkgs.fd}/bin/fd . --changed-within 100s /musi/dot.torrents/ -x touch || true
      '';
      startAt = "*:*:0";
    };
  }
  # Binary cache
  {
    nix.settings = {
      substituters = [ "http://${hosts.musi.address}:4977" ];
      trusted-public-keys = [ "key-name:2xd0yVuRgg0DXo4g+xnkYMkiEs8HvnnvU8c+yBhgAIs=" ];
    };
    # Upgrade after musi (which does upgrade at "04:40") so that it has already built shared packages
    system.autoUpgrade.dates = "05:10";
  }
]
