{ lib, config, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    ## shell environnement
    moreutils
    tmux
    fzf # fuzzy finder
    asciinema # Terminal JSON recorder & player. Check asciinema.org

    ## processus
    htop # process viewer
    pstree
    lsof # list open files
    cpulimit # limit process CPU usage

    ## network
    mtr # interactive trace route
    iftop # connection viewer
    nmap # local network prober
    librespeed-cli # Speedtest

    ## protocols
    curl # HTTP client
    wget # HTTP client
    lftp # FTP client

    ## developpement
    git
    python3
    shellcheck # bash linter

    ## database
    sqlite-interactive # Heavy version with readline and completion support.

    ## hardware
    lm_sensors # CPU temp
    parted # disk partition manager

    ## files
    file # file types
    dos2unix
    fd # find like
    ripgrep # grep like
    exa # ls like
    du-dust # du like
    pydf # df like
    tiv # terminal image viewer
    rdfind # find duplicates
    zip
    unzip
    unrar

    ## security
    srm # secure rm
    gnupg # reference OpenPGP implementation
    pass

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
