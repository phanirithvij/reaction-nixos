{ ... }:
{
  services.nginx.virtualHosts."premium-car-import.ppom.me" = {
    forceSSL = true;
    enableACME = true;
    locations."/".proxyPass = "http://192.168.1.25:80";
  };
}
