{ config, pkgs, ... }:
{
  services.journald.extraConfig = ''
    SystemMaxUse=6G
    MaxRetentionSec=1month
  '';
}
