{ lib, pkgs, config, ... }:
with lib;                      
let
  user =        "joris";
  serviceName = "minecraft";
  home =        "/home/${user}/";
  directory =   "/home/${user}/dr_cobblestone/";
  jar =         "/home/${user}/dr_cobblestone/mohist-1.12.2-146-server.jar";
  domain =      "dr.cobblestone.ppom.me";
  port =        2077;
in
{
  ## User conf
  users.users = {
    "${user}" = {
      isNormalUser = true;
      packages = with pkgs; [ bash jre ];
      home = home;
      openssh.authorizedKeys.keys = [
        # Joris's key
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgQDMwm/SE3y5gBkp19toGlXzar1XQdH6n7WAdg458QFSk1m2PSFd3BhAmfI5GxIwNnWXBW8KPQzGx1wJ92oTXaCXP0CTMNKm/DM5AhGqYsp/he5GI9rQNlogFo35zc6nSFgrDTB/P/4JgkTK5QRAXlSjyet1UkxgOnejnDnK7gsTvw== joris@joris-4DV-Kraken"
        # Alexis's key
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC9hKCqRvKrcJ5zLE50eQuOokNBVUfjBFCgwqVrNYA4qENd3mug+ViLkF89PQ+8a6PSFiTDpvBEqFfV1HnF6FeB6yKUUUgBliMt0lKO2T+y0UfsEuNcYt9Wg9B4xX8TuTANcz4013n/EBBNFsZ51DuMRpFRY9hujGc6JW38TbN4hOCSrw9DSVtjcCvvhLHkUUN3V98+uYs6lczyiovuPgCVWtb92EX1ttQmk/WwysBenH9tJHxXVMo+EZsJCCWbFTwE3kbzTphjDY9oj5O9sZUPDCGsWN/maQQhP18OocPWOxN42A/4Jwm0rQrTB2Mu5e339WgYFAYcKRcA43TPluUF alexis@MSI"
      ];
    };
  };
  # Allow user to start and stop the server
  # TODO: For some reason, the user has to type their password even if NOPASSWD directive is set.
  security.sudo.extraConfig = ''
    ${user} ALL=(root) NOPASSWD: /run/current-system/sw/bin/systemctl start ${serviceName}
    ${user} ALL=(root) NOPASSWD: /run/current-system/sw/bin/systemctl start ${serviceName}.service
    ${user} ALL=(root) NOPASSWD: /run/current-system/sw/bin/systemctl stop  ${serviceName}
    ${user} ALL=(root) NOPASSWD: /run/current-system/sw/bin/systemctl stop  ${serviceName}.service
  '';

  ## Service conf
  # open ports on the firewall
  networking.firewall.allowedTCPPorts = [ port ];
  networking.firewall.allowedUDPPorts = [ port ];
  # systemd unit
  systemd.services."${serviceName}" = {
    enable = true;
    description = "Minecraft server";
    after = ["network.target"];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      User = "${user}";
      ExecStart = "${pkgs.jre}/bin/java -jar ${jar}";
      WorkingDirectory="${directory}";
    };
  };
}
