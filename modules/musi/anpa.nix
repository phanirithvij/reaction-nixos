{ lib, config, pkgs, ... }:
let
  myPort = 8476;
  myUsers = [
    { name = "anpa"; ssh = [ "anpaSSH" ]; uid = 2000; }
    {
      name = "tanina";
      ssh = [ "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAntIo1HtgaMr8Z1UqqUeUurXd/TRXLJY+ecCqO7MFzmg7Nhjm7JTrW4hi6Tzje61HRWnSKClBwkoB6xowEp7xSx2tYXSZ6IoAdKjHHSfR+oWO7EkEsOBY+L1wBTkKqpXoPXE+D1Vq2AfAcaBvHOg/k2yuXFlsrqraK76Wrm1R+x1jMR/5IzpPneCl96xLPakwivuqTOzdx/4Zrpm7bHa52ayuuUJnWZJ9pDCc4lUblNiYDK7P2W/AdHEW+CTm+/v0lbjazBRaElkzrSxw+q/LegxhwE4y8M/NcKN8kqm7GDvv/uE7a6RU5JBw8MC5y/++/s4B2rPjGkq1vzA8xYGCFQ== rsa-key-20220220" ];
      uid = 2001;
    }
    {
      name = "rdelaage";
      ssh = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDF8SKnbtxnN6L1RapClrlbfvGjIzr5DQWFjLmPKUsSPKg2i09S4tAeiIMDkGzJrsoqKaBg4I07bdjIf6piUPqcvASFJJkPC8PEuFn18j56VK1bkXH3/dHroLWvVhl3Lnt3WtFDoQ45At9oaDU5nUE63WZp5Sp1PcmMjKHMuBibAc+BBG8M2N6+qt7JU0IPc2fXqqKj5FZ65zPDIC5sGZ8tAwFmqxiqxHzw72NJcE00UMiBjCEvs0gdNeG/EhrPKTM6rzioXBQefWtsUttseIUN0xHJ6qdMRXaPB8j5aqskCr862WxrMIkkP8zC3V8MwFl6GL5tGJN+42fcDFoMes/xgBVV++wMtInSM/McWBsCD7sBhSfolTtFiiCbnC8qjJwG/yyvsnKHtyvGS58TZSFt58Ets2XiN8uzM+VSmqIDrn7zj9dMiFIH5XWU596+mWwoq0cY9w3s3LBzDO/yDUziRs4qsTX8Sai434PZV7ml5YPc3mlrX8A8/kLaAiLW7ps= rdelaage@rdelaage01" ];
      uid = 2002;
    }
    {
      name = "akesi";
      ssh = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC08+b5KB8zco6O2AwJNXCgrq1tnECP5ySkTBG4GCyg0+OLa/j/TWDr3EqWvOKcY7cH9Mlc7bwLVCPgYrdjYkmwK/6DLYm129utEZx3g3jkIE53xicD3VEv6ahh/ElTm/wqrPtpCPL8GDL8+nMEJw1w7kVQPdFRVt50570AtFSN8zKapyyOJx2L0F+ek/i4reYdZrSrLv0GOovWEz3+vUesiqsB3y8AlMwTOdgevhaCmM/7cdLMTHoYjqs5dOo8nvDKqaqYjOd3OpckRYUmmgK4+cR35DB8QF9Rrt+GEh8uqYApA7BcFNDnttUQPUU+I2HcHtFoY/QQMj/E5sfImcSiI1TlAwgV6J0kjXWbkydxojr4YXCyVFRYm6t9kcJQsO7A/82VzQgRLKNWw9OwEIMzhNXyt/z0DaQ7wf2kXG96Ms80DAZj8DfLuBMiQauEidj/0Jfv0ERIWUz0i6RyTnZIvRJIjZPTgvk8Vm6rJ0QX3HubGG+zOMB+ql8TB0CSLhU= root@akesi"
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCsCcIgTiT0HDv9zP44IIIvUUsgTSwX+7DpvHX4V2zsu511Yc9ow+9sP/JGu06iXeQS562WkR33A5kIB3CT/tyxeOwge7TmJRU2RhSjxF9ILUumlwO5/DylFThatwUgMfpYEnBB8StSLk6udTgHEiwCYIgGm+9Z4/qJMvumQVM+KP0QPzVVBsbcj2eZELJifIeKAaLXx3ODOPzJ2Huj4sJL3+esvKioawXtimkpeOsbfRvdeK9JchVKzDNh4ZkoxacjwsEe9ETY06/VvdIimKUqPBoaLpe3m9rBNqkXt+iWNF/OKgonc+tcw2l6WJ7ALmHOUAZWvukrTlHJ8PrOmH0y4WlekuJtTwH6tSOFOFgprIwYp8q9Pq0dYBVGdUJnpOj/hz73qsELXMmoFB/i7Bn9gkSykNGsLbu/O3+dZNJQKlAjAEp0/WbQ38CkxMYobo5iZ1VEGuwdTwTx9R+r+ngT+VpZ21n05leJhLXnrASO0nMvNRhAGC/56bvLV+L/iR0= ao@sona"
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCcoJI8MHBEmMrvs/eFMVoG6N9wvdej+qJIx2NGOTRrIraNvU+yAIgdvfVvMror26E98NCQK0SMhS2aO4P8bSO6G/duUF7OgzxMecfLhPY1aQxNLgTIzcm+6jf+HkCqKZc6jZV8TnyqsebUkkDrVmiAy5SszvkqiuTppvOoUJE/rFHcoN4HKlOat5eF+aPmbdwut5rMjOW/PJh1f/Td2fKbzRsaDYQxo/00BH9h7tsaK+hb60iia0fZIAy5HPIBbvtmEnw+0PYary47AYQ0Pp6FWqkxj+YB4gFkJxOQxyeQiPIUa9iucuLRv2gGr2pU8E6zGHclg3MkeHnU97yf1svna1AdkTpBcYbRRNdsO2jr1LKdtcqLAqwtpE3M8s+xbEEsq5FmkpIctD48vDWVL01QCWSrHHm+m19b4MVs2omUDsGa1SrO+7XouGHazs0l4DMwqffo+0wHWxz3kRhXKTjFOYHF1OnsFDsmhmoGouIrla7fL73bEwK1dS1Ii0+ASv7qjo9YSSqBK2J5gz5E/a3SBLSxI1EoaVvvAazMo4TpAY1QAvOYeuOIC+hSRDEb0qM2HKN8rfOyrXqGZ7lBRpvzeLrPHnQBKGtz/TVTUlAVfWOxfePmI6mToeEmlNyDj6Fp+pXN/+BZzUgQMXTB60BlUB8h3SAxoIgGpxkzS7A1gQ== corentin@corentin-desktop-1"
      ];
      uid = 2003;
    }
  ];
  transitDir   = user: "/data/user-uploads/${user.name}";
  containerDir = user: "/home/${user.name}/upload-here";
in {
  networking.firewall.allowedTCPPorts = [ myPort ];

  # Permits private networking
  boot.kernelModules = [ "veth" ];

  # Ensure permissions on host
  # FIXME must launch `systemd-tmpfiles --create` from time to time to fix permissions
  systemd.tmpfiles.rules = (builtins.map
    (user: "d ${transitDir user} 750 ${builtins.toString user.uid} users - -")
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
      imports = [ ../common/ssh.nix ];

      ppom.ssh = {
        enable = true;
        port = myPort;
        hardened = false;
      };

      system.stateVersion = "21.11";

      users.users = builtins.listToAttrs (map (user: lib.nameValuePair
        "${user.name}"
        {
          isNormalUser = true;
          openssh.authorizedKeys.keys = user.ssh;
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
