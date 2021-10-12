{ lib, config, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    ## shell environnement
    moreutils
    tmux
    fzf # fuzzy finder

    ## processus
    htop # process viewer
    # pstree
    lsof # list open files
    cpulimit # limit process CPU usage

    ## network
    mtr # interactive trace route
    iftop # connection viewer
    nmap # local network prober
    librespeed-cli # Speedtest

    ## protocols
    curl # HTTP client

    ## developpement
    git
    python3
    shellcheck # bash linter

    ## files
    file # file types
    fd # find like
    ripgrep # grep like
    exa # ls like
    du-dust # du like
    pydf # df like

    ## security
    srm # secure rm
    gnupg # reference OpenPGP implementation
    pass

  ] ++ lib.optionals (! config.ppom.isLight) [

    asciinema # Terminal JSON recorder & player. Check asciinema.org
    tiv # terminal image viewer
    rdfind # find duplicates
    zip
    unzip
    # unrar # unfree!

    ## protocols
    wget # HTTP client
    lftp # FTP client

    ## database
    sqlite-interactive # Heavy version with readline and completion support.

    ## hardware
    lm_sensors # CPU temp
    parted # disk partition manager

    ## containers
    ctop
    docker-compose
    docui

    ## video
    ffmpeg-full
    mkvtoolnix
    youtube-dl
    handbrake

    ## text
    dos2unix
    vtt2srt # VTT to SRT converter

    ## nixeries
    nox
    nix-du
    patchelf

  ];


  nixpkgs.overlays = [
    (self: super: {
      # go vtt2srt script
      vtt2srt = super.callPackage ../../pkgs/vtt2srt {}; 
    })
  ];
}
