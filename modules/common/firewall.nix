{ lib, ... }:
let
  # https://docs.censys.com/docs/opt-out-of-data-collection
  bannedRanges4 = [
    "66.132.159.0/24"
    "162.142.125.0/24"
    "167.94.138.0/24"
    "167.94.145.0/24"
    "167.94.146.0/24"
    "167.248.133.0/24"
    "199.45.154.0/24"
    "199.45.155.0/24"
    "206.168.34.0/24"
    "206.168.35.0/24"
  ];
  bannedRanges6 = [
    "2602:80d:1000:b0cc:e::/80"
    "2620:96:e000:b0cc:e::/80"
    "2602:80d:1003::/112"
    "2602:80d:1004::/112"
  ];
  ban = iptables: iprange: "${iptables} -I INPUT -s ${iprange} -j DROP\n";
in
{
  networking.firewall.extraCommands = lib.concatStringsSep "\n" (
    (builtins.map (ban "iptables") bannedRanges4) ++ (builtins.map (ban "ip6tables") bannedRanges6)
  );
}
