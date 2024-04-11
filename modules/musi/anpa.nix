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
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBrSvK7feOr37nP0hdOylZG1GzYBssHtVrWGs3/0zFha bertille@ordi"
      ];
      uid = 2003;
    }
    {
      name = "fallstar";
      ssh = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDhHg9zYgR15EqE8b0gf6ojj276X5cpJfGw8hFa/zrnKt4rh93NFS1Ouvai/XxCF1GD+eGJbkGPauuiQ8ICtyOXjjU5Yp2PcntDpc4F4hyokyaEYc+3CcElLeqXeJIoTZ2g2wCKd7MS92EUtN6Bqb5ld70d/KyV7Nh2k2T91/PYAFUUJhKPvcvy3mMb3BzDdwnDWdavO9THvZOaJfsgZKupctdYKI47uQEyUkm+syDnMYVaTflhWVEM4BK6MwiIif+0wEF8RPo413MpY/ECuo7B5L5MA8l1vD9t8mYqKAfUNWr7DB70hlQ2YLH1macXAiUNx+8sg04QgNXNglSEWfK7 fallstar@hyperion"
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQChX2AiSUnkOPU+F9Rc2BMidg/PXPsjINd0aT+3bc0/eZ03pHby1SI0DXHooc8lACuhf0IKGFC9wzZReG4hngSRimqBgH6/7xo6rruEVcigDU43UHCrtjPUwAr1GAa190TgNVnNQssvAVTYxSXK9mhoXFW/U7j4iygJHkAlSWhIx99gozcYV6RYP68uuArctw5C+QpdZhQgd3LcEpcMxxaEhOnB6DWzJzPHWuGcowDsOJbxHVhJVXmRv0vU4xOWuku70z8G3s0YmMk4IeSALfRE3KidbMdAVOqWAdgSezwDN7rf9lFKRcP4gAlXge5hHk2FLnkn+2PGrskrOM13vOaT funkwhale@dionysos"
      ];
      uid = 2005;
    }
    {
      name = "guillaume";
      ssh = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDLNfnP6zlA9+RDf9cVmwlzFBwAxGIPnoWcSp0oRWIJl5EEsqakAdPhuJRRi3xfbmpJwkQHpBC1G2IGaicuMdKZjUnwuYJm4NsxaSr7sVMRTbbm1DBnF21KMMhZxQ3upwoD+26bl8o3AhqreQ1gX7z8AjpDm2yAaWQEXtr3cseLKNJjwtLldZQd48e3w1UZgATLkQuw0Tno1FEjAiYJQpuZLZ3Di3wp+uHMmDTQl6CBhR6kUy1BsnccLNykRE8LYlsy/SSlBnkH3LKfz9i1GdgAdzHAifISaecRlV9SqOwZIMdbHlIR/RqdYen13by3wntECFfGZHfvzmr0uNLm8avnPKQNsoYDpPia1sptcnABSnqtWP63QdLYEnct2BW5tYdeICPary6HIr6jFZfGTgtPGigXiUBH7AbirB+Byn3wBal2wV2jI56FBRLCvcXfGlFcTSE6z+75SFEG3iW937tf0jody+Jez4dYn6MaAaPI2zf62Kd2vvdRohbi4z/WwKc= guillaume@desktop" ];
      uid = 2006;
    }
    {
      name = "babos";
      ssh = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCuWuggpkvPYEZhKva+VrC/TE9HZj9dQNgtMO4NeT3bxjvZ6RLI4GrTCfxErKEVrS6U9pa03aFrIqYiKRl8QKNNstMEhpRfuSEkeVKHKPVI+1IMasL+77nyR1FhKX4rb9h6PBNTYB1yWRYsqxCL27TqjjaXwcQdsdtkYrhV7m0VrZVvFfMVqBohH3t1r0Fw+0+7hDYFuiEjqgpKSL17NhUY9NY9OwFF7btb1J8F2A4DgTwXbQO5tnmxQUncaKMVfskArtjHu0wvnAcPhmaa3uNC+Z+6mJkH9JlUrU84Qk3tdD0MJlVVaQLXZxB6rJbmslC9CqG8QOUSVcRflvattldyEae0c4KtUjx3siioq7eUF0hlwA0veWB4G3YCxGwoG49FGRBQO2BEtdbeFJka6SeWlO+RMTQqqFZqG450ruZVg1NNo79m18QKllcACrYUYh62iX8t3GAJ66L9J3CU1A3olxDmy5V2d0W90UQonvc6jb7O58AR5x/YL2Ldh9i8T3s= bertille@marvin" ];
      uid = 2007;
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
  systemd.services.systemd-tmpfiles-create = {
    description = "FIXME must launch `systemd-tmpfiles --create` from time to time to fix permissions";
    serviceConfig.ExecStart = "${pkgs.systemd}/bin/systemd-tmpfiles --create";
    startAt = "*:0/15:0";
  };

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
