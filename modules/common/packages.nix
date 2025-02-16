{ lib, config, pkgs, ... }:
{
  options.ppom.packages = {
    enable = lib.mkEnableOption "install ppom packages";
    more = lib.mkEnableOption "install more utilities";
    xdg = lib.mkEnableOption "install xdg utilities";
  };
  config = {
    # no default tools (perl)
    environment.defaultPackages = lib.mkDefault [];

    # no desktop things
    xdg = lib.mkIf (!config.ppom.packages.xdg) {
      autostart.enable = lib.mkDefault false;
      icons.enable = lib.mkDefault false;
      mime.enable = lib.mkDefault false;
      sounds.enable = lib.mkDefault false;
    };

    environment.systemPackages = with pkgs; [
      man-pages # standard man pages
      ## shell environnement
      (lib.lowPrio moreutils)
      fzf # fuzzy finder

      ## nix
      nixos-option # print the actual value of a NixOS option
      nvd # print versions and changes of packages across nix closures
      nix-diff # prints differences between two derivations, ex: `nix-diff /nix/var/nix/profiles/system-{n,n+1}-link`
      (import (fetchFromGitHub {
        owner = "diamondburned";
        repo = "nix-search";
        rev = "v0.3.1";
        sha256 = "sha256-2N1xy9BK9o7j/vk42Pg/nvDjDt7nZlannCLCcS8Puuk=";
      }))

      ## processus
      htop # process viewer
      glances # system and process viewer
      lsof # list open files
      # cpulimit # limit process CPU usage
      strace # show syscalls

      ## network
      rsync
      # bind # dig
      iftop # connection viewer
      nmap # local network prober
      librespeed-cli # Speedtest
      # tcpdump
      (lib.lowPrio inetutils)

      ## protocols
      curl # HTTP client
      # goaccess # HTTP Log parser

      ## developpement
      git
      # python3
      shellcheck # bash linter

      ## files
      file # file types
      fd # find like
      ripgrep # grep like
      eza # ls like
      du-dust # du like
      diskonaut # like dust, but interactive
      pydf # df like
      jq # json swiss-army-knife

      ## security
      srm # secure rm
      gnupg # reference OpenPGP implementation
      # crowdsec # powerfull, go alternative to fail2ban, with community database

    ] ++ lib.optionals config.ppom.packages.more [
      fish # Friendly interactive shell
      python3
      bc # basic calculator

      go # golang
      gopls # go language server

      # asciinema # Terminal JSON recorder & player. Check asciinema.org
      # tiv # terminal image viewer
      # rdfind # find duplicates
      zip
      unzip
      trash-cli
      # unrar # unfree!

      ## protocols
      wget # HTTP client
      # lftp # FTP client
      # httping # ping an URL.
      # simple-http-server

      ## database
      sqlite-interactive # Heavy version with readline and completion support.

      ## hardware
      # lm_sensors # CPU temp
      parted # disk partition manager
      testdisk # file & disc recovery

      ## video
      ffmpeg-full
      # mkvtoolnix
      yt-dlp
      # handbrake
      # gpac # MP4Box

      # nix-related
      nurl # nix prefetching (generate src = ... from URL)
      nix-init # automagically create go,rust,python,zig package

      ## text
      dos2unix
      # vtt2srt # VTT to SRT converter
      # subedit # Subtitle Editor
      subshift # Personal subtitle editor
    ];


    nixpkgs.overlays = [
      (self: super: {
        # go vtt2srt script
        vtt2srt = super.callPackage ../../pkgs/vtt2srt {};
        subshift = super.callPackage ../../pkgs/subshift {};
      })
    ];
  };
}
