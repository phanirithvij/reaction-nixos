{ lib, config, pkgs, ... }:
let 
  hosts = builtins.fromTOML (builtins.readFile ../common/hosts.toml);
in {
  options.ppom.musi-cache = {
    enable = lib.mkEnableOption "use musi as a Nix cache";
  };
  options.ppom.remote-build = {
    allow-musi = lib.mkEnableOption "allow musi to perform remote builds";
    hosts = lib.mkOption {
      description = "perform remote builds on those hosts";
      default = [];
      type = lib.types.listOf lib.types.str;
    };
  };
  config = lib.mkMerge [

    (lib.mkIf config.ppom.musi-cache.enable {
      nix.settings = {
        # Put it after cache.nixos.org, which has faster bandwidth
        # So that we pull only custom packages from musi
        substituters = lib.mkAfter [ "http://${hosts.musi.address}:4977" ];
        trusted-public-keys = [ "key-name:2xd0yVuRgg0DXo4g+xnkYMkiEs8HvnnvU8c+yBhgAIs=" ];
      };
      # Upgrade after musi (which does upgrade at "04:40") so that it has already built shared packages
      system.autoUpgrade.dates = "05:10";
    })

    (lib.mkIf config.ppom.remote-build.allow-musi {
      # Not upgrading by itself anymore
      system.autoUpgrade.enable = lib.mkForce false;
      # Letting musi build and switch the system
      nix.settings.allowed-users = [ "musi-build" ];
      nix.settings.trusted-users = [ "musi-build" ];
      users.users.musi-build = {
        isSystemUser = true;
        useDefaultShell = true; # Must be allowed to login
        group = "musi";
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPw4sNMQdBpffsmyUwiL/oPsJRs9iqX77BAbMRCtQtai root@musi"
        ];
      };
      users.groups.musi = {};
      security.sudo-rs.extraRules = [
        {
          users = [ "musi-build" ];
          commands = [
            {
              command = "ALL";
              options = [ "NOPASSWD" ];
            }
          ];
        }
      ];
    })

    {
      systemd.services = lib.mkMerge (map (hostName: let
        host = hosts.${hostName};
      in {
      "rebuild-${hostName}" = {
        enable = true;
        wantedBy = [ "nixos-upgrade.service" ];
        after = [ "nixos-upgrade.service" ];
        environment = {
          NIX_SSHOPTS = lib.concatStringsSep " " [
            "-i /var/secrets/remote-build/key"
            "-o StrictHostKeyChecking=accept-new"
          ];
          NIX_PATH = lib.concatStringsSep ":" [
            "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos"
            "/nix/var/nix/profiles/per-user/root/channels"
          ];
        };
        path = [
          config.services.openssh.package
        ];
        serviceConfig = {
          Type = "oneshot";
          Slice = "nix.slice";
          ExecStart = lib.concatStringsSep " " [
            "${pkgs.nixos-rebuild}/bin/nixos-rebuild switch"
            "--target-host musi-build@${host.address}"
            "--use-remote-sudo"
            "-I nixos-config=/etc/nixos/modules/${hostName}/default.nix"
          ];
        };
      };
    })
    config.ppom.remote-build.hosts);
  }
];
}
