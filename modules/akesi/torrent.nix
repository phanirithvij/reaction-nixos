{ lib, config, pkgs, ... }:

let
  sshMountPath = "/musi";
  sshHostPart = "akesi@musi.ppom.me";
  sshPathPart = "/home/akesi/";
  sshFullPath =  "${sshHostPart}:${sshPathPart}";
  sshPrivateKey = "/var/secrets/musi/id_rsa";
in
{
  services.transmission = {
    enable = true;
    openPeerPorts = true;
    # openRPCPort = true; # FIXME uncomment
    performanceNetParameters = true;
    # credentialsFile = "/var/secrets/transmission/auth.json";
    settings = {
      incomplete-dir = "${sshMountPath}/downloading";
      download-dir = "${sshMountPath}/upload-here";
      watch-dir = "${sshMountPath}/dot.torrents";
      watch-dir-enabled = true;
      # rpc-bind-address = "0.0.0.0";
      # rpc-username = "ppom";
      # rpc_authentication_required = false;
    };
  };

  # Où j'en suis :
  # Je n'arrive pas à me connecter en RPC avec transmission-remote-gtk. J'ai commenté ce qui est relatif à rpc. penser à ajouter ssl ensuite.
  # Je passe par le dossier d'uploads

  environment.systemPackages = with pkgs; [
    sshfs
    stig
  ];

  # systemd.tmpfiles.rules = [
  #   "d ${sshMountPath} 750 transmission transmission -"
  # ];

  systemd.mounts = [
    {
      type = "fuse.sshfs";
      what = sshFullPath;
      where = sshMountPath;
      options = lib.concatStringsSep "," [
        "_netdev"
        "allow_other"
        "default_permissions"
        "port=8476"
        "IdentityFile=${sshPrivateKey}"
        "reconnect"
        "ServerAliveInterval=10"
        "ServerAliveCountMax=5"
        "x-systemd.automount"
        "uid=${builtins.toString config.users.users.transmission.uid}"
        "gid=${builtins.toString config.users.groups.transmission.gid}"
      ];
      mountConfig = {
        TimeoutSec = 20;
      };
      wantedBy = [ "transmission.service" ];
      before = [ "transmission.service" ];
    }
  ];
}
