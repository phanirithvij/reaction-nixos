# This configuration file is designed to only contain package-related entries.
{ pkgs, ... }:

let 
  f-mpv-with-scripts = pkgs.mpv-unwrapped.wrapper {
    mpv = pkgs.mpv-unwrapped;
    scripts = with pkgs.mpvScripts; [ mpris ];
  };
in {
  environment.systemPackages = with pkgs; [
    # CLI
    sshuttle # VPN-over-SSH
    mosh # alternative to SSH that bootstraps over it
    # sysstat # iostat
    # tealdeer # tldr man pages
    tomb # LUKS wrapper
    pinentry-gnome3 # GUI password prompt (used by gpg-agent, installing it in global path for rbw & tomb)
    rbw # unofficial bitwarden CLI
    pass # password-store
    acpi # battery information
    # libossp_uuid # uuid v4
    # pup # jq for HTML
    # xsv # jq for CSV
    openvpn
    # lolcat
    # figlet
    # espeak-ng
    # cowsay
    inotify-tools # Linux filesystem watchdog
    # languagetool # Proofreading program
    # deepl-translate-cli # CLI to use deepl. With a shell wrapper around it, it's fast to use
    # signalbackup-tools # Manipulate Signal smartphone backups.
    restic # Backup

    # TUI
    # w3m # web browser
    # asuka # gemini browser
    # ytfzf # Youtube scrapper ⨯ fzf
    khal # calendar
    vdirsyncer # caldav syncer
    toot # CLI/TUI for Mastodon
    helix # neovim alternative

    # Desktop environment
    alacritty # terminal
    st # backup terminal if OpenGL bugs
    feh # image viewer
    dunst # notification daemon
    libnotify # send notifications
    peek # GIF screenshots
    pavucontrol # Pulseaudio GUI
    # ncpamixer # Pulseaudio TUI
    networkmanagerapplet # NM connection editor
    playerctl # media play pause
    wl-mirror

    # GUI apps
    (wrapFirefox (firefox-unwrapped.override { pipewireSupport = true;}) {}) # Best browser ever
    thunderbird # Mail, CalDav, XMPP & Matrix client
    ungoogled-chromium # Alternative browser
    signal-desktop # Signal Messaging client
    # lagrange # Gemini browser
    # element-desktop # Matrix heavy client
    # tor-browser-bundle-bin
    # pcmanfm # File Browser
    gnome-keyring # for fractal
    fractal # Gnome Matrix desktop client
    evince
    libreoffice
    mpv-no-scripts
    mpv-with-scripts
    # clementine # music player
    cheese # webcam
    qpwgraph # play with pipewire streams
    # ocenaudio # test ardour?
    gimp # GNU Image Manipulation Program
    inkscape # Vector Image Editor
    deluge # BitTorrent peer
    gparted
    # syncthing # ± P2P file synchronization
    # apache-directory-studio # LDAP client
    # klavaro # learn to type efficiently
    # tigervnc

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
    spr # Make PRs from one commit
    # git-branchless # git enhancement
    # jj # git replacement (git compatible)
    # gource
    so # stack overflow TUI
    gnumake
    # h2 # H2 Database Editor
    alejandra # Nix formatter
    zola # static site generator
    tailwindcss # CSS generation framework
    (pkgs.callPackage ../../pkgs/directus2zola {})
    # gcc-wrapper
    # sqlitebrowser
    mmctl # mattermost control (for Picasoft's server management)
    # (quarto.override { rWrapper = null; python3 = null; }) # Markdown environment based on pandoc
    minisign # small utility to sign files
    ansible
    opentofu
    tokei # SLOC counter
    hexyl # pretty hexdump
    reveal-md

    docker
    # docker-compose # for SiMDE's Portail des assos
    # virt-manager
    # wireshark
    # vscodium
    python3
    # python39
    # python39Packages.pip
    # nodejs cargo
    nushell
    deno
    cargo
    rustc
    rust-analyzer # Rust language server
    rustfmt # Rust formatter
    clippy # Rust liner
    # rustup # Rust upstream packages. Only used for local std doc.
    gcc
    go

    # Sysadmin
    # tdns-cli # dig alternative

    # Network
    wireguard-tools

    # Media
    imagemagick
    ocrs # OCR tool
    # beets # MP3 tag editor from MusicBrainz
    # kid3 # MP3 tag editor
    # cdparanoia # CD ripper, `cdparanoia -B`
    # yj # YAML to JSON etc.
    # pandoc
    # texlive.combined.scheme-small
    # pdftk # PDF Swiss knife
    # poppler # other PDF manipulations
    # pngquant # png size reducer

    # dofus
  ];

  nixpkgs.overlays = [
    (self: super: {
      # add rofi-emoji plugin
      rofi = super.rofi.override { plugins = [
        super.rofi-emoji
        super.rofi-mpd
      ]; };

      # soude_au_cou = super.callPackage /home/ao/prg/rust/sudoku {}; 

      deepl-translate-cli = super.callPackage ../../pkgs/deepl-translate-cli {}; 

      soweli = super.callPackage ../../pkgs/soweli {};

      ocrs = super.callPackage ../../pkgs/ocrs {};

      mpv-no-scripts = pkgs.stdenv.mkDerivation {
        inherit (pkgs.mpv) meta;
        version = "yay";
        pname = "mpv-no-scripts";
        buildInputs = [ pkgs.mpv ];
        src = pkgs.mpv;
        installPhase = ''
          mkdir -p $out/bin
          ln -s $src/bin/mpv $out/bin/mpvnoscripts
        '';
      };

      mpv-with-scripts = f-mpv-with-scripts;

      ytfzf = super.ytfzf.override { mpv = f-mpv-with-scripts; };

      dofus = let
        url = "https://launcher.cdn.ankama.com/installers/production/Dofus_3.0-x86_64.AppImage";
      in pkgs.writeShellScriptBin "dofus" ''
        ${pkgs.appimage-run}/bin/appimage-run ${pkgs.fetchurl {
          inherit url;
          sha256 = "sha256-yqdqxD5YfrODX4p0Rh8LqUn5/nrHciyvJfb7WC9BTW4=";
        }}
      '';

      # zola = super.zola.overrideAttrs (final: prev: {
      #   patches = [
      #     # provides `zola serve --store-html`
      #     (pkgs.fetchpatch {
      #       url = "https://github.com/getzola/zola/commit/d23eded6bcd95d475340b3bf40d7d4eb17c028e3.diff";
      #       sha256 = "sha256-xrxs2Qk3lBTGK7ji7Vxv9WqH6+o0p8EsxvbOqvuDb1c=";
      #     })
      #     # provides `save_as_file` Tera function
      #     # (pkgs.fetchpatch {
      #     #   url = "https://github.com/ppom0/zola/commit/404de294ffc3b3e2e15952790c41ade74bb7d935.diff";
      #     #   sha256 = "sha256-KZnYxGEiFNF/6dHIbWLcI7I0QI/Uz8v8edd4XXieD2M=";
      #     # })
      #   ];
      # });

    })
    # (import /home/ao/prg/nix/gomod2nix/overlay.nix)
  ];

  fonts.packages = with pkgs; with xorg; [
    noto-fonts
    noto-fonts-cjk-sans
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
