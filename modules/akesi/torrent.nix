
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
    # openPeerPort = true;
    # openRPCPort = true;
    performanceNetParameters = true;
    # credentialsFile = "/var/secrets/transmission/auth.json";
    settings = {
      incomplete-dir = "${sshMountPath}/downloading";
      download-dir = "${sshMountPath}/upload-here";
      # rpc-bind-adresses = "0.0.0.0";
      # watch-dir = ...
      # watch-dir-enabled = true;
    };
  };

  environment.systemPackages = with pkgs; [ sshfs ];

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
      wantedBy = [ "deluged.service" ];
      before = [ "deluged.service" ];
    }
  ];
}
