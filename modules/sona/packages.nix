# This configuration file is designed to only contain package-related entries.
{ lib, config, pkgs, ... }:

let 
  f-mpv-with-scripts = super: super.wrapMpv super.mpv-unwrapped {
    scripts = with super.mpvScripts; [ mpris youtube-quality ];
  };
in {
  environment.systemPackages = with pkgs; [
    # CLI
    # sshuttle # poor's man VPN
    sshfs-fuse # mount remote FS via SSH
    (lib.lowPrio moreutils) # vipe, vidir
    sysstat
    tealdeer # tldr man pages
    # sequoia # modern OpenPGP implementation
    tomb # LUKS wrapper
    rbw # unofficial bitwarden CLI
    (lib.hiPrio (pkgs.writeScriptBin "rbw-rofi" ''
      set -eu
      set -o pipefail
      rbw unlock
      rbw ls --fields folder,name,user | sed 's/\t/\//g' | sort | rofi -dmenu | sed 's/^[^\/]*\///' | sed 's/\// /' | xargs -r rbw get | xclip -l 1 -selection clipboard
    ''))
    pinentry-gnome # GUI password prompt (used by gpg-agent, installing it in global path for rbw & tomb)
    acpi # battery information
    # powertop # power information
    # pciutils # lspci
    libossp_uuid # uuid v4
    # vmtouch # Virtual Memory Toucher
    # xonsh # Python x Bash = xon.sh
    # sl # You shouldn't type `sl`...
    jq # JSON shell toolbox
    pup # jq for HTML
    # xsv # jq for CSV
    # parallel
    openvpn
    # lolcat
    # figlet
    espeak-ng
    # cowsay
    # subdl
    # croc # CLI file transfer
    # nix-bundle # Bundle a derivation like AppImage
    # comma # wrapper around `nix-index` && `nix run` to launch a command without installing it
    inotify-tools # Linux filesystem watchdog
    # languagetool # Proofreading program
    trash-cli
    deepl-translate-cli # CLI to use deepl. With a shell wrapper around it, it's fast to use
    signalbackup-tools # Manipulate Signal smartphone backups.

    # TUI
    # w3m # web browser
    # asuka # gemini browser
    # ddgr # DuckDuckGo CLI
    # lookatme # Terminal MarkDown viewer, unmaintained?
    ytfzf # Youtube scrapper ⨯ fzf
    # aerc # Email client
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
    # qsudo # graphical sudo
    xdotool # programmatically move the mouse, type, etc.
    numlockx # set Num Lock
    xss-lock # for use with a screen locker
    flameshot # advanced screenshots
    peek # GIF screenshots
    redshift # less 'blue' screen
    pavucontrol # Pulseaudio GUI
    ncpamixer # Pulseaudio TUI
    # ponymix # Pulseaudio CLI
    rofi # Menu chooser (dmenu like)
    networkmanagerapplet # NM connection editor


    # GUI apps
    firefox # Best browser ever
    thunderbird # Mail, CalDav, XMPP & Matrix client
    ungoogled-chromium # Alternative browser
    signal-desktop # Signal Messaging client
    # code-server # VSCodium w/ in-browser client & server
    mumble # Mumble VoIP client
    # anki
    # drawio
    tor-browser-bundle-bin
    # jitsi-meet-electron
    # element-desktop
    pcmanfm # File Browser
    evince
    libreoffice
    mpv-no-scripts
    mpv-with-scripts
    clementine
    gnome3.cheese
    # ocenaudio # test ardour?
    gimp # GNU Image Manipulation Program
    deluge # BitTorrent peer
    nicotine-plus # Soulseek client
    gparted
    syncthing # ± P2P file synchronization
    apache-directory-studio # LDAP client
    ferdi # Web client for apps (Mattermost, Nextcloud, Telegram…)
    # nextcloud-client
    # rssguard
    klavaro # learn to type efficiently

    # Games
    # superTux superTuxKart
    vitetris
    # wine lutris
    # _2048-in-terminal
    # blobby
    # soude_au_cou # my own game!

    # Development
    git
      # gitAndTools.git-filter-repo
      # gource
      gti
    gnumake
    # ghc stack cabal-install # haskell
    h2 # H2 Database Editor
    simple-http-server
    # gomod2nix
    # alejandra # Nix formatter
    zola # static site generator
    # gcc-wrapper
    # linx-server
    sqlitebrowser

    docker
    # virt-manager # unstable fails to build
    # wireshark
    # vscodium
    python39
    python39Packages.pip
    # nodejs cargo

    # Sysadmin
    tdns-cli # dig alternative

    # Network
    wireguard-tools

    # Media
    # subtitleeditor
    imagemagick
    beets # MP3 tag editor
    # Markdown to PDF
    # yj # YAML to JSON etc.
    # pandoc
      # texlive.combined.scheme-full # 3GB 😬
    # pdftk # PDF Swiss knife
    # poppler # other PDF manipulations
    # multimarkdown # "from Markdown" exports

    # adv_coreutils # with patch, see below
    mediahandler # ⏯️
  ];

  nixpkgs.overlays = [
    (self: super: {
      # add rofi-emoji plugin
      rofi = super.rofi.override { plugins = [
        super.rofi-emoji
        super.rofi-mpd
      ]; };

      # issue in the way the signal-desktop/default.nix transform the spellcheckLanguage. Should be "fr-any"
      # see https://github.com/NixOS/nixpkgs/issues/113346
      signal-desktop = super.signal-desktop.override { spellcheckerLanguage = "fr_ANY"; };

      # dwm override
      dwm = super.callPackage ../../pkgs/dwm {};

      # sudoku game
      # soude_au_cou = super.callPackage /home/ao/prg/rust/sudoku {}; 

      # media handler
      mediahandler = super.callPackage ../../pkgs/mediahandler {}; 

      # linx-server for development.
      linx-server = super.callPackage ../../pkgs/linx-server {}; 

      # deepl cli
      deepl-translate-cli = super.callPackage ../../pkgs/deepl-translate-cli {}; 

      # add -g/--progress to coreutils' cp and mv.
      # adv_coreutils = (super.coreutils.overrideAttrs (oldAttrs: {
      #   doCheck = false;
      #   patches = oldAttrs.patches ++ [
      #     (super.fetchurl {
      #       url = "https://raw.githubusercontent.com/jarun/advcpmv/master/advcpmv-0.9-9.0.patch";
      #       sha256 = "sha256-k6Ii44DV8xjzh+ebSLW3ZHyyNlj0vuPgbHPIESCm4iM=";
      #     })
      #   ];
      # }));

      mpv-no-scripts = pkgs.stdenv.mkDerivation {
        version = "yay";
        pname = "mpv-no-scripts";
        buildInputs = [ pkgs.mpv ];
        src = pkgs.mpv;
        installPhase = ''
          mkdir -p $out/bin
          ln -s $src/bin/mpv $out/bin/mpvnoscripts
        '';
        meta = pkgs.mpv.meta;
      };

      mpv-with-scripts = f-mpv-with-scripts super;

      ytfzf = super.ytfzf.override { mpv = f-mpv-with-scripts super; };

    })
    (import /home/ao/prg/nix/gomod2nix/overlay.nix)
  ];

  fonts.fonts = with pkgs; with xorg; [
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
    # mplus-outline-fonts
    dina-font
    proggyfonts
  ];
}
