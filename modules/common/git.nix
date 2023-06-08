{ lib, config, pkgs, ... }:
{
  options.ppom.git = {
    enable = lib.mkEnableOption "enable ppom git";
    email = lib.mkOption {
      type = lib.types.str;
    };
  };
  config = lib.mkIf config.ppom.git.enable {
    programs.git = {
      enable = true;
      config = {
        user.name = "ppom";
        user.email = config.ppom.git.email;
        core = {
          # Default ssh's askpass is a pain
          askPass = "";
          pager = "delta";
        };
        difftool.tool = "vimdiff";
        difftool.prompt = false;
        credential.helper = "cache --timeout=${builtins.toString (4 * 60 * 60)}";
        commit.verbose = true;
        pull.rebase = false;
        alias = {
          d = "diff";
          dc = "diff --cached";
          dt = "difftool";
          s = "status";
          a = "add -A";
          cm = "commit -m";
        };
      };
    };
    environment.systemPackages = [ pkgs.delta ];
  };
}
