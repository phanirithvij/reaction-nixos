{ lib, config, pkgs, ... }:
let
  myPort = 8476;
  myUsers = [
    { name = "anpa"; ssh = "anpaSSH"; uid = 2000; }
    {
      name = "tanina";
      ssh = "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAntIo1HtgaMr8Z1UqqUeUurXd/TRXLJY+ecCqO7MFzmg7Nhjm7JTrW4hi6Tzje61HRWnSKClBwkoB6xowEp7xSx2tYXSZ6IoAdKjHHSfR+oWO7EkEsOBY+L1wBTkKqpXoPXE+D1Vq2AfAcaBvHOg/k2yuXFlsrqraK76Wrm1R+x1jMR/5IzpPneCl96xLPakwivuqTOzdx/4Zrpm7bHa52ayuuUJnWZJ9pDCc4lUblNiYDK7P2W/AdHEW+CTm+/v0lbjazBRaElkzrSxw+q/LegxhwE4y8M/NcKN8kqm7GDvv/uE7a6RU5JBw8MC5y/++/s4B2rPjGkq1vzA8xYGCFQ== rsa-key-20220220";
      uid = 2001;
    }
    {
      name = "rdelaage";
      ssh = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDF8SKnbtxnN6L1RapClrlbfvGjIzr5DQWFjLmPKUsSPKg2i09S4tAeiIMDkGzJrsoqKaBg4I07bdjIf6piUPqcvASFJJkPC8PEuFn18j56VK1bkXH3/dHroLWvVhl3Lnt3WtFDoQ45At9oaDU5nUE63WZp5Sp1PcmMjKHMuBibAc+BBG8M2N6+qt7JU0IPc2fXqqKj5FZ65zPDIC5sGZ8tAwFmqxiqxHzw72NJcE00UMiBjCEvs0gdNeG/EhrPKTM6rzioXBQefWtsUttseIUN0xHJ6qdMRXaPB8j5aqskCr862WxrMIkkP8zC3V8MwFl6GL5tGJN+42fcDFoMes/xgBVV++wMtInSM/McWBsCD7sBhSfolTtFiiCbnC8qjJwG/yyvsnKHtyvGS58TZSFt58Ets2XiN8uzM+VSmqIDrn7zj9dMiFIH5XWU596+mWwoq0cY9w3s3LBzDO/yDUziRs4qsTX8Sai434PZV7ml5YPc3mlrX8A8/kLaAiLW7ps= rdelaage@rdelaage01";
      uid = 2002;
    }
  ];
  transitDir   = user: "/data/user-uploads/${user.name}";
  containerDir = user: "/home/${user.name}/upload-here";
in {
  networking.firewall.allowedTCPPorts = [ myPort ];

  # Permits private networking
  boot.kernelModules = [ "veth" ];

  # Ensure permissions on host
  systemd.tmpfiles.rules = (builtins.map
    (user: "d ${transitDir user} - - - -")
    myUsers
  );

  # Nat to give internet access
  # networking.nat.enable = true;
  # networking.nat.internalInterfaces = [ "ve-anpa" ];
  # networking.nat.externalInterface = "enp6s0";

  containers.anpa = {
    # privateNetwork = true;
    # hostAddress = "192.168.100.1";
    # localAddress = "192.168.100.10";
    autoStart = true;
    bindMounts = {
      "/data/music" = {
        hostPath = "/data/funkwhale/music/beet";
        isReadOnly = true;
      };
      "/data/video" = {
        hostPath = "/data/streama/movies";
        isReadOnly = true;
      };
    } // builtins.listToAttrs (map
      (user: lib.nameValuePair
        (containerDir user)
        {
          hostPath = (transitDir user);
          isReadOnly = false;
        }
      )
      myUsers
    );
    forwardPorts = [
      {
        hostPort = myPort;
        containerPort = myPort;
        protocol = "tcp";
      }
    ];
    hostBridge = "anpa";
    config = {
      system.stateVersion = "21.11";
      services.openssh = {
        enable = true;
        ports = [ myPort ];
      };
      # Fail2ban service
      services.fail2ban.enable = true;
      # Stick with default banaction, banaction-allports, bantime
      services.fail2ban.jails.sshd = ''
        enabled = true
        port = ${builtins.toString myPort}

        maxretry = 5
        findtime = 1200
        bantime = 2400
      '';
      networking.firewall.allowedTCPPorts = [ myPort ];
      users.users = builtins.listToAttrs (map (user: lib.nameValuePair
        "${user.name}"
        {
          isNormalUser = true;
          openssh.authorizedKeys.keys = [ user.ssh ];
          uid = user.uid;
        }
      ) myUsers);

      # Ensure permissions on container
      systemd.tmpfiles.rules = (builtins.map
        (user: "d ${containerDir user} 700 ${user.name} nobody -")
        myUsers
      );

      documentation.enable = false;
    };
  };
}
