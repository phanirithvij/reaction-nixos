{ lib, config, pkgs, ... }:
let
  port = 58234;
  ip = "10.1.1.1";
  musiIp = "10.1.1.2";
  mountName = "musi";
  mountPath = "/${mountName}";
in lib.mkMerge [
  # Wireguard
  {
    environment.systemPackages = [ pkgs.wireguard-tools ];
    networking = {
      firewall.allowedUDPPorts = [ port ];
      wg-quick.interfaces.nasin = {
        address = [ "${ip}/32" ];
        privateKeyFile = "/var/secrets/wireguard/privatekey";
        listenPort = port;
        peers = [
          {
            endpoint = "musi.ppom.me:${toString port}";
            publicKey = "/Tcl/+rIl3OVZXyLUz9e3hhHKJdhFspEbwztQzT0mFg=";
            allowedIPs = [ "${musiIp}/32" ];
          }
        ];
      };
    };
  }
  # NFS
  {
    services.nfs.server.enable = true;
    environment.systemPackages = [ pkgs.nfs-utils ];
    boot.kernelModules = [ "nfs" ];
    systemd.mounts = [
      {
        type = "nfs";
        what = "${musiIp}:/data/akesi";
        where = mountPath;
      }
    ];
  }
  # Transmission
  {
    systemd.services.transmission = {
      after = [ mountName ];
      requires = [ mountName ];
    };
    services.transmission = {
      enable = true;
      openPeerPorts = true;
      # openRPCPort = true; # FIXME uncomment
      performanceNetParameters = true;
      # credentialsFile = "/var/secrets/transmission/auth.json";
      settings = {
        incomplete-dir = "${mountPath}/downloading";
        download-dir = "${mountPath}/upload-here";
        watch-dir = "${mountPath}/dot.torrents";
        watch-dir-enabled = true;
        speed-limit-up = 2 * 1024; # KB/s
        speed-limit-up-enabled = true;
        rpc-bind-address = ip;
        rpc-username = "ppom";
        rpc_authentication_required = false;
      };
    };

    networking.firewall.extraCommands = ''
      iptables -A nixos-fw -p udp --dport 9091 -s ${musiIp}/24 -j nixos-fw-accept
    '';

    environment.systemPackages = with pkgs; [
      # stig # currently broken
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
]
