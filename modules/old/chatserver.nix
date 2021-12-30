{ lib, pkgs, config, ... }:
with lib;
let
  serviceName = "chatserver";
  port = 10800;
  package = (pkgs.callPackage ../../pkgs/chat.nix {});
in
{
  ## User conf
  users.users = {
    "${serviceName}" = {
      isSystemUser = true;
      packages = [ package ];
      group = serviceName;
    };
  };

  ## Service conf
  # open port on the firewall
  networking.firewall.allowedTCPPorts = [ port ];
  # systemd unit
  systemd.services."${serviceName}" = {
    enable = true;
    description = "Minichat server";
    after = ["network.target"];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      User = "${serviceName}";
      ExecStart = "${package}/bin/chatserver";
      CPUWeight = "20";
      CPUQuota  = "10%";
    };
  };
}
