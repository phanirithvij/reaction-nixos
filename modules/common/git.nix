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
        # Default ssh's askpass is a pain
        core.askPass = "";
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
  };
}
