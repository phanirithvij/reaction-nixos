let
  pkgs = import <nixpkgs> {};

  debugVm = { modulesPath, ... }: {
    imports = [
      # The qemu-vm NixOS module gives us the `vm` attribute that we will later
      # use, and other VM-related settings
      "${modulesPath}/virtualisation/qemu-vm.nix"

      ../common
    ];

    ppom = {
      enable = true;
      git.email = "pakala@ppom.me";
      nvim.enableNixd = false;
    };

    services.reaction = {
      enable = true;
      settingsFile = "/root/reaction.jsonnet";
    };

    system.stateVersion = "23.11";

    # Forward the hosts's port 2222 to the guest's SSH port.
    # Also, forward the MQTT port 1883 1:1 from host to guest.
    virtualisation.forwardPorts = [
      { from = "host"; host.port = 2222; guest.port = 22; }
    ];

    # Use nftables
    networking = {
      nftables.enable = true;
    };
    # environment.systemPackages = with pkgs; [ nftables ];

    # Root user without password and enabled SSH for playing around
    services.openssh = {
      enable = true;
      settings.PermitRootLogin = "yes";
    };
    users.extraUsers.root.password = "";
  };
in
  (pkgs.nixos [ debugVm ]).config.system.build.vm
