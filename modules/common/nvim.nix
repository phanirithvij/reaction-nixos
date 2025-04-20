{ lib, config, pkgs, ... }:
let
  unstable = import <nixos-unstable> {
    config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) (map lib.getName [ pkgs.vscode ]);
  };

  undoquit-vim = pkgs.vimUtils.buildVimPlugin {
    pname = "undoquit-vim";
    version = "2021-05-16";
    src = pkgs.fetchFromGitHub {
      owner = "AndrewRadev";
      repo = "undoquit.vim";
      rev = "74d2a1fc51af91d8b758ad85fb236b6476c8ed0c";
      sha256 = "1a5h0iwmk3fd5qs8wa7v9kys8k2q52jwp71s8c4j0z6c5k1173wn";
    };
    meta.homepage = "https://github.com/AndrewRadev/undoquit.vim";
  };

  vim-svelte = pkgs.vimUtils.buildVimPlugin {
    pname = "vim-svelte";
    version = "2022-10-27";
    src = pkgs.fetchFromGitHub {
      owner = "evanleck";
      repo = "vim-svelte";
      rev = "0e93ec53c3667753237282926fec626785622c1c";
      sha256 = "sha256-sZcHLBCGvCk8px1FlIU+JwDbHS1e7neeXMMQLPoCYe8=";
    };
    meta.homepage = "https://github.com/evanleck/vim-svelte";
  };

in {
  options.ppom.nvim = {
    enable = lib.mkEnableOption "enable ppom git";
    steroids = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Neovim but on steroids";
    };
    enableNixd = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable nixd language server (unstable)";
    };
    enableGo = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable go language server";
    };
  };

  config = let
    cfg = config.ppom.nvim;
  in lib.mkIf cfg.enable {

    environment = {
      variables = {
        EDITOR = "nvim";
        VISUAL = "nvim";
      };
      systemPackages = let nodes = pkgs.nodePackages; in [
        pkgs.neovim
      ] ++ lib.optionals cfg.enableNixd [
        unstable.nixd
      ] ++ lib.optionals cfg.enableGo [
        pkgs.gopls
      ] ++ lib.optionals cfg.steroids [
        # pkgs.nodejs
        # pkgs.pylizer # not packaged yet
        nodes."@tailwindcss/language-server"
        nodes.bash-language-server
        # nodes.svelte-language-server
        # nodes.typescript-language-server
        # nodes.vls # vue-language-server
        pkgs.ccls
        pkgs.gopls
        pkgs.jdk11
        pkgs.jdt-language-server
        pkgs.jsonnet
        pkgs.jsonnet-language-server
        # pkgs.ltex-ls # TODO replace by ltex-plus when packaged
        pkgs.lua-language-server
        pkgs.ruff
        pkgs.typescript-language-server
        pkgs.yaml-language-server
        pkgs.vscode-langservers-extracted # requires vscode to build
      ];
    };

    nixpkgs.overlays = [
      (self: super: {
        neovim = super.neovim.override {
          withNodeJs = cfg.steroids;
          withRuby = true; # todo replace undoquit-vim and get rid of ruby
          viAlias = true;
          vimAlias = true;
          configure = {
            customRC = ''
              lua << EOF
              enableNixd = ${if cfg.enableNixd then "true" else "false"}
              enableGo = ${if cfg.enableGo then "true" else "false"}
              steroids = ${if cfg.steroids then "true" else "false"}
              ${builtins.readFile ./init.lua}
              EOF
            '';
            packages.myVimPackage = let plugins = pkgs.vimPlugins; in {
              start = [
                # Waiting for https://github.com/LnL7/vim-nix/issues/49 to be fixed
                (super.vimPlugins.vim-nix.overrideAttrs (oldAttrs: {
                  patches = [ ./vim_nix_comment.patch ];
                }))
                plugins.far-vim # Find and replace across entire directory
                plugins.guess-indent-nvim # Does it really work?
                plugins.mkdir-nvim # Automatically creates directories on file saving
                undoquit-vim # Reopen closed window with ctrl-w_ctrl-u # uses Ruby
                plugins.vim-commentary # Comment/Uncomment with gc operator
                plugins.vim-fish
                plugins.vim-fugitive # Git support. :Gdiffsplit etc.
                plugins.vim-repeat # Provide undo/redo for vim-commentary & vim-surround
                plugins.vim-surround # ds ys operators for delete or add surrounding "'( etc.
                # plugins.vim-unimpaired # useful but you have to learn the all the shortcuts
                # plugins.nvim-cmp plugins.cmp-buffer plugins.cmp-path # useful but I start keeping things simple
                plugins.papercolor-theme # Light theme
                (super.vimPlugins.gruvbox.overrideAttrs (oldAttrs: {
                  patches = [ ./true_black_gruvbox.patch ];
                }))
              ] ++ lib.optionals (cfg.steroids || cfg.enableNixd || cfg.enableGo) [
                unstable.vimPlugins.nvim-lspconfig
              ] ++ lib.optionals cfg.steroids [
                plugins.tabular # used by vim-markdown
                plugins.unicode-vim # search unicode with :Unicode & i_ctrl-x_ctrl-z
                plugins.vim-markdown
                plugins.vim-visual-multi # multiple cursors with i_ctrl-n
                vim-svelte
                plugins.vim-terraform
                plugins.vim-jsonnet
                plugins.nvim-jdtls
              ];
              opt = [ ];
            };
          };
        };
      })
    ];
  };
}
