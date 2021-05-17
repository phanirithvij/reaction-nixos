{ lib, config, pkgs, ... }:

let
  name = "sona.local";
  rootDirectory = "/home/hdd/ao/vid/";
in {
  networking.firewall.allowedTCPPorts = [ 80 ];

  users.users.nginx.extraGroups = [ "users" ];

  networking.extraHosts = ''
    127.0.0.1 ${name}
  '';

  # Fucking sandboxing
  systemd.services.nginx.serviceConfig.ProtectHome = "read-only";

  # Start only on demand
  systemd.services.nginx.wantedBy = lib.mkForce [];
  systemd.services.nginx-config-reload.wantedBy = lib.mkForce [];

  # Nginx
  services.nginx = {

    additionalModules = with pkgs.nginxModules; [
      fancyindex
    ];

    enable = true;
    enableReload = true;
    clientMaxBodySize = "4G";
    # Enable all recommended settings
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    # Hosts config
    virtualHosts."${name}" = {
      # makes it the default host
      default = true;
      # locations
      locations."/" = {
        root = rootDirectory;
        extraConfig = ''
          fancyindex on;
          fancyindex_exact_size off;
        '';
        # index = "index.html";
      };
    };
  };
}
