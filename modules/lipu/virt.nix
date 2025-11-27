{
  lib,
  config,
  pkgs,
  ...
}:
{

  # virtualisation.libvirtd.enable = true;
  # virtualisation.libvirtd.onBoot = "ignore";
  # systemd.services.libvirtd.wantedBy = lib.mkForce [];
  # systemd.services.libvirt-guests.wantedBy = lib.mkForce [];

  virtualisation.docker.enable = true;
  virtualisation.docker.enableOnBoot = false;
  systemd.services.docker.wantedBy = lib.mkForce [ ];

  # virtualisation.lxd.enable = true;
  # systemd.services.lxd.wantedBy = lib.mkForce [];
}
