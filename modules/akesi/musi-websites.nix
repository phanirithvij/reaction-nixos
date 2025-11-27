{ ... }:
{
  users.users."musi-uploader" = {
    isNormalUser = true;
    group = "musi-uploader";
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC0DRrxfZFRGlFBF16h7YqRPRLxoN0wrE+aklNJyLAKHro0bbIY7oxvLJUdLQculrqIHntwoDzXtVnDMcakzgmiAvbSH1Gy7iUTxfu7GrwsC1vOIeRtywhKuhnu9g/D3/3duDoGnuYRiEZHJT8+MJs1MpGm9la7cBS0nPi1Yy6wms1PVg75Xkk90ck9lc/phuU1caDXW1KG+iw9PxfNZIvrmWPdjsXxtvaje675qJ3iB0m8yiKJXNazKmMGDirLrSrO0IQeU53EbsEMosaTIlDAfl20/e63gL6JVCwvvsa9E6MV94wABgZ3nKkRHduTXYhfFZ6eMZJMfgF1bwFnMZXV9OSL0pSey0V4Rx/gi/lob04l05dCpv5BXH/UOD3HYcTNj4SzW9PfnoGUmA+aQ5TCnFg8I/Xw7ot9OPYycQKkcKMPf7aVS5OlUxA1zw+xlKcvSZD8PivtplMapT2q0bzzbHJnLEE3WoPYLKAPG9dDdGWdg0vXWZ45uqGKtggeliwQImCYbXuFyM0pYxzxPVZQE0+UDH0Jc1k5BeqrDIZww/ECspLpZXYZtimzXPfsZlyhQPfNyVRzlI8Dxjpj6AB28sVdW4Q+TVxRQH2KcbOv37CciK6mglI8mA8bxXo4U4III1zK+6ocqBbIL2+PDCpkS8PTmi5ks0kBSNJkZRGyCQ== root@musi"
    ];
  };
  users.groups."musi-uploader" = { };

  systemd.tmpfiles.rules = [
    "d /var/www/pompeani.art 755 musi-uploader musi-uploader -"
    "d /var/www/static/bdo 755 musi-uploader musi-uploader -"
  ];

  services.nginx.virtualHosts = {
    "pompeani.art" = {
      enableACME = true;
      forceSSL = true;
      locations = {
        "/".root = "/var/www/pompeani.art";
        "^[^.]+[^/]$".return = "301 $request_uri/";
        # "~* \\.webp$".extraConfig = ''
        #   expires 30d;
        #   add_header Vary Accept-Encoding;
        # '';
      };
    };
    "www.pompeani.art" = {
      enableACME = true;
      forceSSL = true;
      locations."/".return = "301 https://pompeani.art$request_uri";
    };
  };
}
