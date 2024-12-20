{ lib, config, pkgs, ... }:
{

  # virtualisation.libvirtd.enable = true;
  # virtualisation.libvirtd.onBoot = "ignore";
  # systemd.services.libvirtd.wantedBy = lib.mkForce [];
  # systemd.services.libvirt-guests.wantedBy = lib.mkForce [];

  virtualisation.docker.enable = true;
  virtualisation.docker.enableOnBoot = false;
  systemd.services.docker.wantedBy = lib.mkForce [];

  # virtualisation.libvirtd = {
  #   enable = true;
  #   qemu = {
  #     package = pkgs.qemu_kvm;
  #     ovmf = {
  #       enable = true;
  #       packages = [pkgs.OVMFFull.fd];
  #     };
  #     swtpm.enable = true;
  #   };
  # };

  # virtualisation.lxd.enable = true;
  # systemd.services.lxd.wantedBy = lib.mkForce [];

  # ssh server for lxc-to-host X11 forwarding
  # services.openssh = {
  #   enable = true;
  #   forwardX11 = true;
  #   passwordAuthentication = false;
  # };
  
  # users.users.ao.openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH131eeXQur97Nur6YIhXBeosKbZU6yqd7QlbYWFrPMC ubuntu@u" ];
}

