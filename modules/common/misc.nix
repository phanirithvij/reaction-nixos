{ lib, config, pkgs, ... }:
{
  options.ppom.misc.enable = lib.mkEnableOption "enable ppom misc";

  config = lib.mkIf config.ppom.misc.enable {

    nix = {
      settings = {
        connect-timeout = 5;
        log-lines = 25;
        auto-optimise-store = true;
        allowed-users = [ "root" ];
      };
      gc = {
        automatic = true;
        dates = "04:00";
        options = "--delete-older-than 15d";
        persistent = false;
      };
      # FIXME update to daemonIOSchedClass daemonIOSchedPriority
      # daemonIONiceLevel = 7;
      # FIXME update to daemonCPUSchedPolicy
      # daemonNiceLevel =   10;
    };

    # Auto upgrade block
    system.autoUpgrade = {
      enable = lib.mkDefault true;
      allowReboot = lib.mkDefault false;
    };
    systemd.services.nixos-upgrade.serviceConfig = {
      # Permit to update all channels (not just default one)
      ExecStartPre = [ "${config.nix.package}/bin/nix-channel --update" ];
      # Seems unused for now https://www.kernel.org/doc/html/v6.1/block/ioprio.html
      # CFQ is the only IO Scheduler concerned but it's only for reads and it
      # is somewhat deprecated
      IOSchedulingClass = "idle";
    };

    environment.shellAliases = {
      n = "cd /etc/nixos/modules";
      sys = "cd /etc/systemd/system";
      ll = "ls -lh";
      la = "ls -a";
      lla = "ls -lha";
      dc = "cd -";
      gti = "git";
      ffmpeg = "ffmpeg -hide_banner";
      ffprobe = "ffprobe -hide_banner";
      booted = ''cat /run/booted-system/boot.json /run/current-system/boot.json | jq -r '."org.nixos.bootspec.v1".kernel' | rg --color never -o "linux-[^/]*"'';
    };

    environment.homeBinInPath = true;

    services.sysstat.enable = true;

    services.fstrim.enable = true;

    services.locate = {
      enable = true;
      localuser = null;
      package = pkgs.plocate;
      prunePaths = lib.mkForce [ "/tmp" "/var/tmp" "/var/cache" "/var/lock" "/var/run" "/var/spool" ];
    };

    environment.systemPackages = with pkgs; [
      sysstat
      atuin
    ];

    programs.bash.interactiveShellInit = ''
      # load fzf key-bindings
        [ -f ${pkgs.fzf}/share/fzf/key-bindings.bash ] && source ${pkgs.fzf}/share/fzf/key-bindings.bash
      # do not load completion because it breaks other completions
      # [ -f ${pkgs.fzf}/share/fzf/completion.bash ] && source ${pkgs.fzf}/share/fzf/completion.bash

      # custom functions
      function nix-dir()  { echo "$(dirname "$(dirname "$(realpath "$(which "$1")")")")"; }
      function nix-cd()   { cd "$(nix-dir "$1")"; }
      function nix-pkgs() { cd /nix/var/nix/profiles/per-user/root/channels/nixos; }
      function nix()      { command nix --offline "$@"; }

      GIT_AUTHOR_DATE="$(date -d '12:00 today')"
      GIT_COMMITTER_DATE="$GIT_AUTHOR_DATE"
      export GIT_AUTHOR_DATE
      export GIT_COMMITTER_DATE


      # Only for non-system users
      if [ "$USER" = "root" ] || [ -d "/home/$USER" ]
      then
        source ${pkgs.bash-preexec}/share/bash/bash-preexec.sh
        eval "$(atuin init bash --disable-up-arrow)"
      fi
    '';

    programs.fish.interactiveShellInit = ''
      function nix-dir; echo (dirname (dirname (realpath (which $argv[1])))); end
      function nix-cd; cd (nix-dir $argv[1]); end
      function nix-pkgs; cd /nix/var/nix/profiles/per-user/root/channels/nixos; end
      function nix; command nix --offline $argv; end

      set -x GIT_AUTHOR_DATE (date -d '12:00 today')
      set -x GIT_COMMITTER_DATE $GIT_AUTHOR_DATE

      atuin init fish --disable-up-arrow | source
    '';

    security = {
      sudo = {
        enable = false;
        extraConfig = ''
          Defaults env_keep += "GIT_AUTHOR_DATE GIT_COMMITTER_DATE"
        '';
      };
      wrappers.sudo = {
        setuid = true;
        owner = "root";
        group = "root";
        source = "${pkgs.doas}/bin/doas";
      };
      doas = {
        enable = true;
        extraRules = [
          {
            groups = ["wheel"];
            persist = true;
          }
          {
            groups = ["wheel"];
            persist = true;
            cmd = "git";
            setEnv = [ "GIT_AUTHOR_DATE" "GIT_COMMITTER_DATE" ];
          }
        ] ++ (map
          (cmd: {
            inherit cmd;
            groups = ["wheel"];
            persist = true;
            setEnv = [ "NIX_PATH" "NIXPKGS_CONFIG" "NIXPKGS_ALLOW_UNFREE" "NIXPKGS_ALLOW_INSECURE" ];
          })
          ["nixos-rebuild" "nix" "nix-shell" "nix-build"]
        );
      };
    };
  };
}
