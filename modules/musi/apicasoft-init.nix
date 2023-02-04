{ lib, config, pkgs, ... }:
let
  mySSHPort = 143;
  myHTTPPort = 81;
  myUsers = [
    # Redacted to preserve participants privacy
    { name = "a_course_admin";              password = "password"; group = "wheel"; }
    { name = "a_course_participant";        password = "password"; group = null; }
  ];
in {
  networking.firewall.allowedTCPPorts = [ mySSHPort ];

  # Permits private networking
  boot.kernelModules = [ "veth" ];

  # services.nginx.virtualHosts."init.ppom.me" = {
  #   forceSSL = true;
  #   enableACME = true;
  #   locations."/".proxyPass = "http://localhost:${toString myHTTPPort}";
  # };

  containers.apicasoftinit = {
    autoStart = true;
    forwardPorts = [
      {
        hostPort = mySSHPort;
        containerPort = mySSHPort;
        protocol = "tcp";
      }
      {
        hostPort = myHTTPPort;
        containerPort = myHTTPPort;
        protocol = "tcp";
      }
    ];
    hostBridge = "apicasoftinit";
    config = {
      services.openssh = {
        enable = true;
        ports = [ mySSHPort ];
        permitRootLogin = "no";
      };

      security.sudo.execWheelOnly = true;
      users.groups.api = {};

      environment.systemPackages = with pkgs; [ nano neovim htop lsof bind git curl wget file fd ripgrep exa pydf du-dust bc python3 gnupg zip unzip ];

      users.users = builtins.listToAttrs (map (user: lib.nameValuePair
      "${user.name}"
      {
        isNormalUser = true;
        password = user.password;
        group = "api";
        extraGroups = lib.optionals (user.group != null) [ user.group ];
      }
      ) myUsers);

      # systemd.tmpfiles.rules = [
      #   "d /home/api 770 ppom api - -"
      # ] ++ (map (user: "d /home/${user.name}        755 ${user.name} - -") myUsers)
      # ++   (map (user: "d /home/${user.name}/public 755 ${user.name} - -") myUsers);

      services.nginx = {
        enable = true;
        package = (pkgs.nginx.override {
          modules = with pkgs.nginxModules; [ fancyindex ];
        });

        virtualHosts.default = {
          default = true;
          listen = [ { addr = "0.0.0.0"; port = myHTTPPort; } ];
          root = pkgs.writeTextDir "index.html" ''
            <!DOCTYPE html>
            <html>
            <head>
              <meta charset="utf8">
              <title>Apicasoft Init</title>
            </head>
            <body>
              <h1>Apicasoft Init</h1>
              <ul>
                ${builtins.concatStringsSep "\n" (map (user: ''<li><a href="/${user.name}/">${user.name}</a></li>'') myUsers)}
              </ul>
            </body>
            </html>
          '';
          locations = lib.mkMerge (map (user: {
            "/${user.name}/" = {
              alias = "/home/${user.name}/public/";
              extraConfig = ''
                fancyindex on;
                fancyindex_exact_size off;
              '';
            };
          }) myUsers);
        };
      };

      systemd.services.nginx.serviceConfig.ProtectHome = "read-only";

      system.stateVersion = "21.11";
    };
  };
}
