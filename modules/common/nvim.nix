{ lib, config, pkgs, ... }:
let
  unstable = import <nixos-unstable> {
    config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) (map lib.getName [ pkgs.vscode ]);
  };

  undoquit-vim = pkgs.vimUtils.buildVimPluginFrom2Nix {
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

  vim-svelte = pkgs.vimUtils.buildVimPluginFrom2Nix {
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
  };

  config = let
    cfg = config.ppom.nvim;
  in lib.mkIf cfg.enable {

    environment = with pkgs; {
      variables = {
        EDITOR = "nvim";
        VISUAL = "nvim";
      };
      systemPackages = [
        neovim
        unstable.nixd
      ] ++ lib.optionals cfg.steroids [
        nodejs
        # Language servers
        gopls
        ltex-ls
        lua-language-server
        rust-analyzer
        unstable.vscode-langservers-extracted # requires vscode to build
        nodePackages."@tailwindcss/language-server"
        nodePackages.svelte-language-server
        nodePackages.bash-language-server
      ];
    };

    nixpkgs.overlays = [
      (self: super: {
        neovim = super.neovim.override {
          withNodeJs = cfg.steroids;
          viAlias = true;
          vimAlias = true;
          configure = {
            customRC = ''
              lua << EOF
              steroids = ${if cfg.steroids == true then "true" else "false"}
              ${builtins.readFile ./init.lua}
              EOF
            '';
            packages.myVimPackage = with pkgs.vimPlugins; {
              start = [
                # Waiting for https://github.com/LnL7/vim-nix/issues/49 to be fixed
                (super.vimPlugins.vim-nix.overrideAttrs (oldAttrs: {
                  patches = [ ./vim_nix_comment.patch ];
                }))
                far-vim # Find and replace across entire directory
                guess-indent-nvim # Does it really work?
                mkdir-nvim # Automatically creates directories on file saving
                undoquit-vim # Reopen closed window with ctrl-w_ctrl-u
                vim-commentary # Comment/Uncomment with gc operator
                vim-fish
                vim-fugitive # Git support. :Gdiffsplit etc.
                vim-repeat # Provide undo/redo for vim-commentary & vim-surround
                vim-surround # ds ys operators for delete or add surrounding "'( etc.
                unstable.vimPlugins.nvim-lspconfig
                # vim-unimpaired # useful but you have to learn the all the shortcuts
                # nvim-cmp cmp-buffer cmp-path # useful but I start keeping things simple
                (super.vimPlugins.gruvbox.overrideAttrs (oldAttrs: {
                  patches = [ ./true_black_gruvbox.patch ];
                }))
              ] ++ lib.optionals cfg.steroids [
                tabular # used by vim-markdown
                unicode-vim # search unicode with :Unicode & i_ctrl-x_ctrl-z
                vim-markdown
                vim-visual-multi # multiple cursors with i_ctrl-n
              ];
              opt = [ ];
            };
          };
        };
      })
    ];
  };
}
