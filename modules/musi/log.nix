{ config, pkgs, ... }:
{
  services.journald.extraConfig = ''
    SystemMaxUse=12G
    MaxRetentionSec=1month
  '';
}
