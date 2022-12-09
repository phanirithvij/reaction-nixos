# This configuration file is designed to only contain package-related entries.
{ lib, config, pkgs, ... }:

let 
  unstable = import <nixos-unstable> {};
  f-mpv-with-scripts = super: super.wrapMpv super.mpv-unwrapped {
    scripts = with super.mpvScripts; [ mpris ];
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
    pinentry-gnome # GUI password prompt (used by gpg-agent, installing it in global path for rbw & tomb)
    pass # password-store
    acpi # battery information
    # powertop # power information
    # pciutils # lspci
    libossp_uuid # uuid v4
    # vmtouch # Virtual Memory Toucher
    # xonsh # Python x Bash = xon.sh
    # sl # You shouldn't type `sl`...
    jq # JSON shell toolbox
    pup # jq for HTML
    bc # basic calculator
    # xsv # jq for CSV
    # parallel
    openvpn
    # lolcat
    # figlet
    # espeak-ng
    # cowsay
    # subdl
    # croc # CLI file transfer
    # nix-bundle # Bundle a derivation like AppImage
    # comma # wrapper around `nix-index` && `nix run` to launch a command without installing it
    inotify-tools # Linux filesystem watchdog
    # languagetool # Proofreading program
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
    feh # image viewer
    dunst # notification daemon
    libnotify # send notifications
    peek # GIF screenshots
    pavucontrol # Pulseaudio GUI
    ncpamixer # Pulseaudio TUI
    networkmanagerapplet # NM connection editor


    # GUI apps
    firefox # Best browser ever
    unstable.thunderbird # Mail, CalDav, XMPP & Matrix client
    ungoogled-chromium # Alternative browser
    unstable.signal-desktop # Signal Messaging client
    # code-server # VSCodium w/ in-browser client & server
    # mumble # Mumble VoIP client
    # anki
    # drawio
    # tor-browser-bundle-bin
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
    inkscape # Vector Image Editor
    deluge # BitTorrent peer
    nicotine-plus # Soulseek client
    gparted
    syncthing # ± P2P file synchronization
    apache-directory-studio # LDAP client
    unstable.ferdium # Web client for apps (Mattermost, Nextcloud, Telegram…)
    # nextcloud-client
    # rssguard
    # klavaro # learn to type efficiently

    # Games
    # superTux superTuxKart
    vitetris
    # wine lutris
    # _2048-in-terminal
    # blobby
    # soude_au_cou # my own game!
    # nxengine-evo # Cave Story NX
    soweli # my own game!

    # Development
    git
      # gitAndTools.git-filter-repo
      # gource
      # gti
    gnumake
    # ghc stack cabal-install # haskell
    h2 # H2 Database Editor
    # gomod2nix
    # alejandra # Nix formatter
    zola # static site generator
    # gcc-wrapper
    sqlitebrowser
    mmctl # mattermost control (for Picasoft's server management)

    docker
    docker-compose # for SiMDE's Portail des assos
    # virt-manager
    # wireshark
    # vscodium
    python39
    # python39Packages.pip
    # nodejs cargo
    rustup
    gcc

    # Sysadmin
    tdns-cli # dig alternative

    # Network
    wireguard-tools

    # Media
    # subtitleeditor (broken)
    imagemagick
    beets # MP3 tag editor
    # cdparanoia # CD ripper, `cdparanoia -B`
    # yj # YAML to JSON etc.
    pandoc
    texlive.combined.scheme-small
    pdftk # PDF Swiss knife
    # poppler # other PDF manipulations

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

      # dwm override
      dwm = super.callPackage ../../pkgs/dwm {};

      # soude_au_cou = super.callPackage /home/ao/prg/rust/sudoku {}; 

      mediahandler = super.callPackage ../../pkgs/mediahandler {}; 

      deepl-translate-cli = super.callPackage ../../pkgs/deepl-translate-cli {}; 

      soweli = super.callPackage ../../pkgs/soweli {};

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

      mpvpaper = super.mpvpaper.overrideAttrs (finalAttrs: previousAttrs: {
        mpv = pkgs.mpv;
      });


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
