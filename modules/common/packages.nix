{ lib, config, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    ## shell environnement
    moreutils
    tmux # terminal multiplexer
    fzf # fuzzy finder

    ## nix
    nixos-option # print the actual value of a NixOS option
    nvd # print versions and changes of packages across nix closures

    ## processus
    htop # process viewer
    lsof # list open files
    cpulimit # limit process CPU usage

    ## network
    bind # dig
    mtr # interactive trace route
    iftop # connection viewer
    nmap # local network prober
    librespeed-cli # Speedtest
    (lib.lowPrio inetutils)

    ## protocols
    curl # HTTP client

    ## developpement
    git
    # python3
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
    testdisk # file & disc recovery

    ## containers
    ctop
    docker-compose
    docui

    ## video
    ffmpeg-full
    mkvtoolnix
    yt-dlp
    handbrake
    gpac # MP4Box

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
      toYaml = super.callPackage ../../pkgs/toYaml {};
    })
  ];
}
