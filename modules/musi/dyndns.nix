{ config, pkgs, ... }:
{
  systemd.services.dyndns =
    let
      python = pkgs.python3.withPackages (p: [ p.ovh ]);
      script = ./dyndns.py;
    in
    {
      startAt = "*:0/10";
      serviceConfig = {
        EnvironmentFile = "/var/secrets/ovh-token";
        Environment = [
          "IP=${pkgs.iproute2}/bin/ip"
          "IFNAME=enp6s0"
        ];
        ExecStart = "${python}/bin/python ${script}";
      };
    };
}
