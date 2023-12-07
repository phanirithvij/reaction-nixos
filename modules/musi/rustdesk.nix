{ lib, pkgs, config, ... }:
let 
  unstable = import <nixos-unstable> {};
in {
  services.rustdesk-server = {
    enable = true;
    openFirewall = true;
    relayIP = "82.66.255.188";
    package = unstable.rustdesk-server;
  };
}
