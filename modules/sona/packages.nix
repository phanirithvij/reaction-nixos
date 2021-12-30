# This configuration file is designed to only contain package-related entries.
{ lib, config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # CLI
    bind
    tmux
      tmuxPlugins.fingers
      tmuxPlugins.pain-control
    sshuttle # poor's man VPN
    sshfs-fuse # mount remote FS via SSH
    (lib.lowPrio moreutils) # vipe, vidir
    sysstat
    tealdeer # tldr man pages
    sequoia # modern OpenPGP implementation
    tomb # useful wrapper around PGP and LUKS
    rbw # unofficial bitwarden CLI
    pinentry-gnome # GUI password prompt (used by gpg-agent, installing it in global path for rbw & tomb)
    acpi # battery information
    powertop # power information
    pciutils # lspci
    libossp_uuid # uuid v4
    vmtouch # Virtual Memory Toucher
    xonsh # Python x Bash = xon.sh
    sl # You shouldn't type `sl`...
    jq # JSON shell toolbox
    xsv # CSV's `jq`
    # parallel
    openvpn
    lolcat figlet espeak-ng cowsay
    subdl
    croc # CLI file transfer
    nix-bundle # Bundle a derivation like AppImage
    inotify-tools # Linux filesystem watchdog
    languagetool # Proofreading program

    # TUI
    w3m # web browser
    asuka # gemini browser
    ddgr # DuckDuckGo CLI
    ytfzf # Youtube scrapper ⨯ fzf
    aerc # Email client
    # neovim-remote

    # Desktop environment
    alacritty # terminal
    st # backup terminal if OpenGL bugs
    conky # status bar
    feh # image viewer
    xorg.xrandr # manage monitors
    xorg.xev # log key and mouse events
    xorg.xkill # kill an unresponsive window
    xclip # X clipboard
    autorandr # xrandr configurations memory
    dunst # notification daemon
    libnotify # send notifications
    qsudo # graphical sudo
    xdotool # programmatically move the mouse, type, etc.
    numlockx # set Num Lock
    xss-lock # for use with a screen locker
    flameshot # advanced screenshots
    peek # GIF screenshots
    redshift # less 'blue' screen
    pavucontrol # Pulseaudio GUI
    ncpamixer # Pulseaudio TUI
    ponymix # Pulseaudio CLI
    rofi # Menu chooser (dmenu like)
    networkmanagerapplet # NM connection editor

    # GUI apps
    firefox
    thunderbird
    ungoogled-chromium
    signal-desktop
    code-server # VSCodium w/ in-browser client & server
    mumble
    # anki
    drawio
    tor-browser-bundle-bin
    # jitsi-meet-electron
    element-desktop
    pcmanfm
    evince
    libreoffice
    mpv
    clementine
    gnome3.cheese
    gimp
    deluge
    gparted
    appimage-run
    syncthing # ± P2P file synchronization
    apache-directory-studio # LDAP client
    # audacity, ardour or ocenaudio?
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
    simple-http-server
    gomod2nix
    linx-server

    docker
    virt-manager
    # wireshark
    # vscodium
    python39
    python39Packages.pip
    # nodejs cargo

    # Sysadmin
    # apache-directory-studio
    tdns-cli # dig alternative

    # Network
    wireguard

    # Media
    subtitleeditor
    imagemagick
    beets # MP3 tag editor
    # Markdown to PDF
    yj # YAML to JSON etc.
    pandoc
      texlive.combined.scheme-full
    pdftk # PDF Swiss knife
    poppler # other PDF manipulations
    multimarkdown # "from Markdown" exports

    adv_coreutils # with patch, see below
    mediahandler # ⏯️
  ];

  nixpkgs.overlays = [
    (self: super: {
      # add rofi-emoji plugin
      rofi = super.rofi.override { plugins = [
        super.rofi-emoji
        super.rofi-mpd
      ]; };

      rbw = (
        (
          super.rbw.override {
            withFzf = true;
            withRofi = true;
            withPass = true;
          }
        ).overrideAttrs (oldAttrs: {
        # add `rbw unlock` at the beginning of the `rbw-rofi` script
        patches = oldAttrs.patches ++ [ ../../pkgs/rbw.patch ];
      }));

      # issue in the way the signal-desktop/default.nix transform the spellcheckLanguage. Should be "fr-any"
      # see https://github.com/NixOS/nixpkgs/issues/113346
      signal-desktop = super.signal-desktop.override { spellcheckerLanguage = "fr_ANY"; };

      # add personnal scripts
      # ppom_config = super.callPackage /home/ao/prg/config {};

      # dwm override
      dwm = super.callPackage ../../pkgs/dwm {};

      # sudoku game
      # soude_au_cou = super.callPackage /home/ao/prg/rust/sudoku {}; 

      # media handler
      mediahandler = super.callPackage ../../pkgs/mediahandler {}; 

      # linx-server for development.
      linx-server = super.callPackage ../../pkgs/linx-server {}; 

      # add -g/--progress to coreutils' cp and mv.
      adv_coreutils = (super.coreutils.overrideAttrs (oldAttrs: {
        doCheck = false;
        patches = oldAttrs.patches ++ [
          (super.fetchurl {
            url = "https://raw.githubusercontent.com/jarun/advcpmv/master/advcpmv-0.9-9.0.patch";
            sha256 = "sha256-k6Ii44DV8xjzh+ebSLW3ZHyyNlj0vuPgbHPIESCm4iM=";
          })
        ];
      }));

    })
    (import /home/ao/prg/nix/gomod2nix/overlay.nix)
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

  programs.thefuck = {
    enable = true;
    alias = "f";
  };
}
