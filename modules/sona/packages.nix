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
    mosh # alternative to SSH that bootstraps over it
    sysstat
    tealdeer # tldr man pages
    tomb # LUKS wrapper
    rbw # unofficial bitwarden CLI
    pinentry-gnome # GUI password prompt (used by gpg-agent, installing it in global path for rbw & tomb)
    pass # password-store
    acpi # battery information
    libossp_uuid # uuid v4
    pup # jq for HTML
    # xsv # jq for CSV
    openvpn
    # lolcat
    # figlet
    # espeak-ng
    # cowsay
    inotify-tools # Linux filesystem watchdog
    # languagetool # Proofreading program
    deepl-translate-cli # CLI to use deepl. With a shell wrapper around it, it's fast to use
    signalbackup-tools # Manipulate Signal smartphone backups.
    restic # Backup

    # TUI
    # w3m # web browser
    # asuka # gemini browser
    ytfzf # Youtube scrapper ⨯ fzf
    khal # calendar
    vdirsyncer # caldav syncer

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
    playerctl # media play pause

    # GUI apps
    unstable.firefox # Best browser ever
    unstable.thunderbird # Mail, CalDav, XMPP & Matrix client
    ungoogled-chromium # Alternative browser
    signal-desktop # Signal Messaging client
    lagrange # Gemini browser
    element-desktop # Matrix heavy client
    # tor-browser-bundle-bin
    pcmanfm # File Browser
    evince
    libreoffice
    mpv-no-scripts
    mpv-with-scripts
    clementine # music player
    gnome3.cheese # webcam
    qpwgraph # play with pipewire streams
    # ocenaudio # test ardour?
    gimp # GNU Image Manipulation Program
    inkscape # Vector Image Editor
    deluge # BitTorrent peer
    gparted
    syncthing # ± P2P file synchronization
    apache-directory-studio # LDAP client
    # klavaro # learn to type efficiently
    tigervnc

    # Games
    # superTux superTuxKart
    vitetris
    # wine lutris
    # _2048-in-terminal
    # blobby
    # soude_au_cou # my own game!
    # nxengine-evo # Cave Story NX
    # soweli # my own game!

    # Development
    git
    gitAndTools.git-filter-repo
    # gource
    gnumake
    h2 # H2 Database Editor
    # alejandra # Nix formatter
    zola # static site generator
    (nodePackages.tailwindcss.overrideAttrs (old: { plugins = [ nodePackages."@tailwindcss/typography" ]; })) # CSS generation framework
    # gcc-wrapper
    sqlitebrowser
    mmctl # mattermost control (for Picasoft's server management)
    unstable.quarto # Markdown environment based on pandoc
    minisign # small utility to sign files

    docker
    docker-compose # for SiMDE's Portail des assos
    # virt-manager
    # wireshark
    # vscodium
    python3
    # python39
    # python39Packages.pip
    # nodejs cargo
    rustup
    gcc

    # Sysadmin
    tdns-cli # dig alternative

    # Network
    wireguard-tools

    # Media
    imagemagick
    beets # MP3 tag editor from MusicBrainz
    kid3 # MP3 tag editor
    # cdparanoia # CD ripper, `cdparanoia -B`
    # yj # YAML to JSON etc.
    pandoc
    texlive.combined.scheme-small
    pdftk # PDF Swiss knife
    # poppler # other PDF manipulations
    pngquant # png size reducer

  ];

  nixpkgs.overlays = [
    (self: super: {
      # add rofi-emoji plugin
      rofi = super.rofi.override { plugins = [
        super.rofi-emoji
        super.rofi-mpd
      ]; };

      zola = super.zola.overrideAttrs (final: prev: {
        patches = [
          # provides `zola serve --store-html`
          (pkgs.fetchpatch {
            url = "https://github.com/getzola/zola/commit/d23eded6bcd95d475340b3bf40d7d4eb17c028e3.diff";
            sha256 = "1i4sq4b0vsxcl5cdd15jnhs2hr8g547s9qpxc4a9lv26bkhz8fmv";
          })
        ];
      });

      # soude_au_cou = super.callPackage /home/ao/prg/rust/sudoku {}; 

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

  fonts.packages = with pkgs; with xorg; [
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
    # mplus-outline-fonts
    dina-font
    proggyfonts
    libertinus
  ];
}
