{ lib, config, pkgs, ... }:
{
  # fileSystems."/musi2" = {
  #   device = "192.168.100.2:/data/user-uploads/akesi";
  #   options = [
  #     # Lazy mounting
  #     "x-systemd.automount" "noauto"
  #     # v3
  #     "nfsvers=3"
  #   ];
  # };
  # environment.systemPackages = [ pkgs.nfs-utils ];
  # boot.kernelModules = [ "nfs" ];
  # systemd.mounts = [
  #   {
  #     type = "nfs";
  #     what = "192.168.100.2:/data/user-uploads/akesi";
  #     where = "/musi2";
  #     options = "_netdev,auto";
  #   }
  # ];
}
