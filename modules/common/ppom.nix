{ lib, config, pkgs, ... }:
{
  options.ppom = {
    isDesktop = lib.mkOption {
      type = lib.types.bool;
      description = "Is it a desktop computer? true is desktop, false is server.";
    };
  };
}

