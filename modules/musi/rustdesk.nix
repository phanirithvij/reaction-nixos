{ lib, pkgs, config, ... }:
let 
  unstable = import <nixos-unstable> {};
in {
  services.rustdesk = {
    enable = true;
    openFirewall = true;
    relayIP = "82.66.255.188";
    package = unstable.rustdesk-server;
  };
}
