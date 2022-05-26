{ lib, config, pkgs, ... }:
let
  # Found here: https://stackoverflow.com/questions/54504685
  recursiveMerge = attrList:
  let f = attrPath:
    lib.zipAttrsWith (n: values:
      if lib.tail values == []
        then lib.head values
      else if lib.all lib.isList values
        then lib.unique (lib.concatLists values)
      else if lib.all lib.isAttrs values
        then f (attrPath ++ [n]) values
      else lib.last values
    );
  in f [] attrList;


  root    = version: "/var/www/pompeani.art-${version}";
  domain  = version: if version == "test" then "test.pompeani.art" else "pompeani.art";
  conf    = version: {

    systemd.tmpfiles.rules = [
      "d ${root version} 755 art art -"
      "d /var/lib/art/build-${version} 755 art art -"
    ];

    services.nginx.virtualHosts."${domain version}" = {
      enableACME = true;
      forceSSL = true;
      locations."/".root = root version;
    };

    # Fail2ban hack to launch build
    services.fail2ban.jails."pompeaniart-${version}" = ''
      enabled = true
      filter = pompeaniart-${version}
      action = pompeaniart-${version}
      maxretry = 0
      findtime = 1
      bantime = 5
    '';

    environment.etc."fail2ban/action.d/pompeaniart-${version}.conf".text = ''
      # Fail2ban action for building the ${version} pompeani.art website
      [Definition]
      actionstart =
      actionstop =
      actioncheck =
      actionban = ${pkgs.systemd}/bin/systemctl start pompeaniart-ci-${version}.service
      actionunban = 
    '';

    environment.etc."fail2ban/filter.d/pompeaniart-${version}.conf".text = ''
      [INCLUDES]
      before = common.conf

      [Definition]
      failregex = client: <ADDR>, server: akesi.ppom.me, request: "GET /build-pompeani.art/${version} HTTP/2.0", host: "akesi.ppom.me"
      ignoreregex =
      journalmatch = _SYSTEMD_UNIT=nginx.service + _COMM=nginx
    '';

    systemd.services."pompeaniart-ci-${version}" = {
      enable = true;
      description = "Building ${version} pompeani.art website";
      serviceConfig = {
        ExecStart = "${pkgs.writeShellApplication {
          name = "ci";
          runtimeInputs = with pkgs; [ git zola fd rsync ];
          text = builtins.readFile ./pompeani.art.ci.sh;
        }}/bin/ci ${version}";
        User = "art";
      };
    };
  };
in recursiveMerge [
  {
    users.users.art = {
      isSystemUser = true;
      group = "art";
    };
    users.groups.art = {};

    services.fail2ban = {
      enable = true;
    };
  }
  (conf "test")
  (conf "master")
]
