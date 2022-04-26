{ lib, config, pkgs, ... }:

with config.ppom;
let
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
    version = "2021-04-21";
    src = pkgs.fetchFromGitHub {
      owner = "evanleck";
      repo = "vim-svelte";
      rev = "5f88e5a0fe7dcece0008dae3453edbd99153a042";
      sha256 = "0p941kcqnv4wgcybmhnpzrvxm2y9d2fkd4n186zav7mwfzn736jq";
    };
    meta.homepage = "https://github.com/evanleck/vim-svelte";
  };

in
{
  imports = [ ./ppom.nix ];

  environment.systemPackages = [
    pkgs.neovim
  ] ++ lib.optionals isDesktop [
    pkgs.nodejs
    pkgs.ruby
    pkgs.black
    pkgs.ccls
  ];

  environment = {
    variables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };
  };

  nixpkgs.overlays = [
    (self: super: {
      neovim = super.neovim.override {
        withNodeJs = isDesktop;
        # nvim aliases
        viAlias = true;
        vimAlias = true;
        configure = {
          customRC = ''
            set number termguicolors
            let g:mapleader = " "
            nnoremap <leader>h noh<CR>
            colorscheme gruvbox

            au TextYankPost * silent! lua vim.highlight.on_yank {on_visual=false}
          '' + lib.optionalString isDesktop ''
            let g:languagetool_jar='${pkgs.languagetool}/share/languagetool-commandline.jar'

            let g:vim_markdown_folding_disabled = 1

            " Function to source only if file exists {
            function! SourceIfExists(file)
              if filereadable(expand(a:file))
                exe 'source' a:file
              endif
            endfunction
            " }
            call SourceIfExists("~/.config/nvim/init.vim")

            " Language plugins put in opt below
            " autocmd FileType php :packadd phpCompletion

            " Coc.nvim stuff (keep it minimal!)
            command! -nargs=0 Format :call CocActionAsync('format')
          '';
          packages.myVimPackage = with pkgs.vimPlugins; {
            start = [
              vim-nix
              vim-commentary
              vim-surround
              vim-repeat
              vim-fugitive
              vim-unimpaired
              vim-fish
              # gruvbox
              (super.vimPlugins.gruvbox.overrideAttrs (oldAttrs: {
                patches = [ ./true_black_gruvbox.patch ];
              }))
            ] ++ lib.optionals isDesktop [
              vim-startify
              fzf-vim
              far-vim
              LanguageTool-nvim
              vim-grammarous
              unicode-vim
              coc-nvim
              coc-json
              coc-html
              # manuals:
              undoquit-vim
              vim-svelte
              rust-vim
              vim-markdown
              mkdir-nvim
              copilot-vim # 😈
            ];
            opt = [ ];
          };
	};
      };
    })
  ];
}
