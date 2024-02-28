{config, pkgs, ...}:
{
  systemd.services.dyndns = {
    startAt = "*:0/10";
    script = ''
      set -e
      TOKEN="$(cat /var/secrets/ydns-token)"
      IPv6="$(${pkgs.iproute2}/bin/ip -j a | ${pkgs.jq}/bin/jq -r '[
        .[]
        | select(.ifname == "enp6s0")
        | .addr_info[]
        | select(.scope == "global")
        | select(.family == "inet6")
        | select(.deprecated == false or has("deprecated") | not)
      ]
      | max_by(.preferred_life_time)
      | .local')"
      ${pkgs.curl}/bin/curl -sS "https://ydns.io/hosts/update/$TOKEN?ip=$IPV6"
    '';
  };

}
