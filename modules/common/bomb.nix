# Adapted from:
# https://lord.re/en/posts/139-gzip-bomb-nginx/
# https://icewind.nl/entry/nixos-add-nginx-options/
{
  config,
  lib,
  ...
}:
let
  bombCfg = config.ppom.bomb;
  vilainLocations = {
    "~* \.php$" = {
      root = bombCfg.root;
      tryFiles = "$1 /${bombCfg.file} =404";
      extraConfig = ''
        add_header Content-Encoding gzip;
        # Those are just to make gixy happy
        add_header Content-Security-Policy "";
        add_header Referrer-Policy strict-origin-when-cross-origin;
        add_header X-Content-Type-Options nosniff;
        add_header X-Frame-Options DENY;
      '';
      priority = 1;
    };
  };
  addedOptions = cfg: {
    bomb = lib.mkOption {
      type = lib.types.bool;
      default = bombCfg.default;
      description = "Bomb PHP requests";
    };
    locations = lib.mkOption {
      apply = value: (lib.optionalAttrs cfg.bomb vilainLocations) // value;
    };
  };
  addedConfig = cfg: {
    locations = lib.optionalAttrs cfg.bomb vilainLocations;
  };
  hostOptions =
    { name, ... }:
    let
      hostCfg = config.services.nginx.virtualHosts.${name};
    in
    {
      options = addedOptions hostCfg;
      config = addedConfig hostCfg;
    };
in
{
  options = {
    ppom.bomb = {
      default = lib.mkEnableOption "bomb php requests";
      root = lib.mkOption {
        type = lib.types.str;
        description = "data dir";
      };
      file = lib.mkOption {
        type = lib.types.str;
        description = "filename in dir";
      };
    };
    services.nginx.virtualHosts = lib.mkOption {
      # the nixos module system will merge the `type` we set with the `type` of the upstream options.
      type = lib.types.attrsOf (lib.types.submodule hostOptions);
    };
  };
}
