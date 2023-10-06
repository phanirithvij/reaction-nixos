{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ehci_pci" "ahci" "usb_storage" "sd_mod" "sr_mod" "sdhci_pci" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/9c149639-52df-4f8c-9f56-6e8720e27661";
    fsType = "ext4";
  };

  fileSystems."/home/hdd" = {
    device = "/dev/disk/by-uuid/0ebcabd7-c195-4ac7-801e-b14f3738f32c";
    fsType = "ext4";
  };

  boot.initrd.luks = {
    reusePassphrases = true;
    devices."crypted" = {
      device = "/dev/disk/by-uuid/51e426d1-48ca-4387-80c0-883593c7108b";
      bypassWorkqueues = true;
    };
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/6496-4938";
    fsType = "vfat";
  };

  swapDevices = [ ];

  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
}
