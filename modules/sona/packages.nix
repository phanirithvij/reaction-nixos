# This configuration file is designed to only contain package-related entries.
{ lib, config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # CLI
    wget # downloader
    curl # downloader
    bind
    (lib.lowPrio inetutils)
    lftp
    nmap # local network prober
    tmux
      tmuxPlugins.fingers
      tmuxPlugins.pain-control
    sshuttle # poor's man VPN
    sshfs-fuse # mount remote FS via SSH
    (lib.lowPrio moreutils) # vipe, vidir
    file # file types
    srm # secure rm
    lsof # list open files
    sysstat
    tealdeer # tldr man pages
    lm_sensors # CPU temp
    sequoia # modern OpenPGP implementation
    gnupg # reference OpenPGP implementation
    tomb # useful wrapper around PGP and LUKS
    pinentry_curses # for tomb passwords on the terminal
    acpi # battery information
    powertop # power information
    cpulimit
    pciutils # lspci
    libossp_uuid # uuid v4
    zip
      unzip
    unrar
    dos2unix
    # gocr tesseract
    vmtouch # Virtual Memory Toucher
    exa fd du-dust ripgrep
      sl
    pstree pydf jq parallel
    xsv # CSV's `jq`
    nox
    nix-du
    patchelf
    pass
    openvpn
    catimg lolcat figlet espeak-ng cowsay
    subdl asciinema
    bc python3
    shellcheck # bash linter
    # vmtouch # touch a file in virtual memory
    croc # CLI file transfer

    # TUI
    # elinks # web browser
    w3m # web browser
    asuka # gemini browser
    htop # process viewer
    iftop # connection viewer
    ddgr # DuckDuckGo CLI
    fzf # fuzzy finder
    weechat # IRC client

    # Desktop environment
    alacritty # terminal
    st # backup terminal if OpenGL bugs
    conky # status bar
    feh # image viewer
    # meh
    xorg.xrandr xorg.xev xorg.xkill xclip
    dunst # notification daemon
    libnotify # send notifications
    qsudo # graphical sudo
    xdotool # programmatically move the mouse, type, etc.
    numlockx # set Num Lock
    xss-lock # for use with a screen locker
    scrot # simple screenshots
    flameshot # advanced screenshots
    redshift # less 'blue' screen
    pavucontrol # Pulseaudio GUI
    ncpamixer # Pulseaudio TUI
    ponymix # Pulseaudio CLI
    rofi
    # GUI apps
    firefox
    thunderbird
    #chromium
    # qutebrowser
    signal-desktop
    mumble
    # qtox
    # anki
    drawio
    #tor-browser-bundle-bin
    #jitsi-meet-electron
    element-desktop
    pcmanfm
    evince
    # libreoffice
    #filezilla
    mpv
    # clementine
    gnome3.cheese
    gimp
    deluge
    gparted
    appimage-run
    # nextcloud-client
    # rssguard

    # Games
    # superTux superTuxKart
    vitetris
    # wine lutris
    _2048-in-terminal
    # blobby
    # soude_au_cou # my own game!

    # Development
    git
      gitAndTools.pass-git-helper
      gource
      gti
    gnumake
    #scilab
    ghc stack cabal-install # haskell
    h2 # H2 Database Editor
    sqlite-interactive # Heavy version with readline and completion support.

    docker
    virt-manager
    # wireshark-qt
    # vscodium
    (lib.lowPrio python2)
    (lib.lowPrio python27Packages.pip)
    python38
    python38Packages.pip
    # nodejs cargo

    # Sysadmin
    # apache-directory-studio
    tdns-cli # dig alternative
    rdfind # find duplicates

    # Media
    ffmpeg-full
    mkvtoolnix
    youtube-dl
    handbrake
    subtitleeditor
    imagemagick
    vtt2srt # VTT to SRT converter
    beets # MP3 tag editor
    # id3v2 kid3 # MP3 tag editors
    # python38Packages.pdftotext
    # Markdown to PDF
    pandoc
      texlive.combined.scheme-medium

    adv_coreutils # with patch, see below
  ];

  nixpkgs.overlays = [
    (self: super: {
      # add rofi-emoji plugin
      rofi = super.rofi.override { plugins = [
        super.rofi-emoji
        super.rofi-mpd
      ]; };
      
      # issue in the way the signal-desktop/default.nix transform the spellcheckLanguage. Should be "fr-any"
      signal-desktop = super.signal-desktop.override { spellcheckerLanguage = "fr_ANY"; };

      # add personnal scripts
      # ppom_config = super.callPackage /home/ao/prg/config {};

      # dwm override
      dwm = super.callPackage /home/ao/prg/dwm {};

      # sudoku game
      # soude_au_cou = super.callPackage /home/ao/prg/rust/sudoku {}; 

      # go vtt2srt script
      vtt2srt = super.callPackage /home/ao/prg/nix/vtt2srt {}; 

      # add -g/--progress to coreutils' cp and mv.
      adv_coreutils = (super.coreutils.overrideAttrs (oldAttrs: {
        doCheck = false;
        patches = oldAttrs.patches ++ [
          (super.fetchurl {
            url = "https://raw.githubusercontent.com/jarun/advcpmv/master/advcpmv-0.8-8.32.patch";
            sha256 = "0iz7p5a8wihnydccb40cjvwxhl8sz9lm7xcd57aqsr1xl7158ki9";
          })
        ];
      }));

    })
  ];

  fonts.fonts = with pkgs; [
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
    mplus-outline-fonts
    dina-font
    proggyfonts
  ];

}
