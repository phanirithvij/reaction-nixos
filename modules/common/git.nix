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
        user = {
          name = "ppom";
          email = config.ppom.git.email;
        };
        core = {
          # Default ssh's askpass is a pain
          askPass = "";
        };
        difftool = {
          tool = "vimdiff";
          prompt = false;
        };
        credential.helper = "cache --timeout=${builtins.toString (4 * 60 * 60)}";
        commit.verbose = true;
        pull.rebase = false;
        alias = {
          d = "diff --ignore-all-space";
          dc = "diff --ignore-all-space --cached";
          dt = "difftool";
          s = "status";
          a = "add -A";
          cm = "commit -m";
          logc = "log -n10 --pretty=format:'%Cred%h%Creset %C(bold blue)(%an) %Creset%Cgreen(%cr)%Creset - %s %C(yellow)%d%Creset' --abbrev-commit";
        };
      };
    };
  };
}
