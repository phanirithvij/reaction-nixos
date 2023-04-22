{ lib, config, pkgs, ... }:
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
    environment.systemPackages = [
      pkgs.neovim
    ] ++ lib.optionals cfg.steroids [
      pkgs.nodejs
      pkgs.black
      pkgs.ccls
    ];

    environment = {
      variables = {
        EDITOR = "nvim";
        VISUAL = "nvim";
      };
    };

    nixpkgs.overlays = [ (self: super: {
      neovim = super.neovim.override {
        withNodeJs = cfg.steroids;
        viAlias = true;
        vimAlias = true;
        configure = {
          customRC = ''
            set number termguicolors
            colorscheme gruvbox

            " save changes in swapfile
            set updatetime=300

            " Open new split panes to right and below
            set splitright
            set splitbelow

            " Terminal Title
            set title
            " Completion look
            set completeopt=noinsert,menuone,noselect
            set shortmess+=c

            " Keep n lines between the cursor and the edge of the screen
            set scrolloff=3

            " Make macros complete faster
            set lazyredraw

            " Insensitive search
            set smartcase
            " Insensitive search in command mode for files and directories
            set wildignorecase
            set ignorecase

            " Show in real time what :s will do
            set inccommand=nosplit
            " Show the match when closing brackets
            set showmatch

            " Do not break words
            set linebreak

            " make = not considered as part of filenames
            set isfname-==

            au TextYankPost * silent! lua vim.highlight.on_yank {on_visual=false}

            " Netrw Tree
            let g:netrw_liststyle = 3
            let g:netrw_banner = 0
            let g:netrw_winsize = 25

            command! RemoveTrailingSpaces %s/\s\+$//
            command! ReplaceAllSpaces %s/ /./g
            command! ReplaceAllPuncts %s/[ \-\[\]()'"_.]\+/./g
            command! TrimDots %s/\.\././g

            " Terminal Configuration
            " tnoremap <C-s> <C-\><C-n><C-w>w
            tnoremap <Esc> <C-\><C-n>
            autocmd TermOpen * set nonu
            autocmd TermOpen * startinsert

            augroup stdout
            autocmd!
            autocmd FileType python     nmap ù yiwoprint(f"<Esc>pa: {<Esc>pa}")<Esc>
            autocmd FileType python     vmap ù   yoprint(f"<Esc>pa: {<Esc>pa}")<Esc>
            autocmd FileType fish       nmap ù yiwoecho <Esc>pa: $<Esc>p<Esc>
            autocmd FileType fish       vmap ù   yoecho <Esc>pa: $<Esc>p<Esc>
            autocmd FileType java       nmap ù yiwoSystem.out.println("<Esc>pa:" + <Esc>pa);<Esc>
            autocmd FileType java       vmap ù   yoSystem.out.println("<Esc>pa:" + <Esc>pa);<Esc>
            autocmd FileType javascript nmap ù yiwoconsole.log('<Esc>pa:', <Esc>pa);<Esc>
            autocmd FileType javascript vmap ù   yoconsole.log('<Esc>pa:', <Esc>pa);<Esc>
            autocmd FileType rust       nmap ù yiwoprintln!("<Esc>pa: {}", <Esc>pa);<Esc>
            autocmd FileType rust       vmap ù   yoprintln!("<Esc>pa: {}", <Esc>pa);<Esc>
            autocmd FileType c          nmap ù yiwoprintf("<Esc>pa: %s", <Esc>pa);<Esc>
            autocmd FileType c          vmap ù   yoprintf("<Esc>pa: %s", <Esc>pa);<Esc>
            autocmd FileType go         nmap ù yiwofmt.Printf("<Esc>pa: %s\n", <Esc>pa)<Esc>
            autocmd FileType go         vmap ù   yofmt.Printf("<Esc>pa: %s\n", <Esc>pa);<Esc>
            augroup END

          '' + lib.optionalString cfg.steroids ''
            let g:languagetool_jar='${pkgs.languagetool}/share/languagetool-commandline.jar'
            let g:languagetool_server_command='${pkgs.languagetool}/bin/languagetool-http-server'
            nmap <space>l :LanguageToolSetUp<CR>:sleep 2<CR>:LanguageToolCheck<CR>

            let g:vim_markdown_folding_disabled = 1
            let g:vim_markdown_toc_autofit = 1

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
            " command! -nargs=0 Format :call CocActionAsync('format')
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
              vim-go
              undoquit-vim
              guess-indent-nvim
              # gruvbox
              (super.vimPlugins.gruvbox.overrideAttrs (oldAttrs: {
                patches = [ ./true_black_gruvbox.patch ];
              }))
            ] ++ lib.optionals cfg.steroids [
              far-vim
              LanguageTool-nvim
              unicode-vim
              # coc-nvim # Switch to 22.05, breaks for now
                # coc-rls # Rust
                # coc-json
                # coc-html
                # coc-xml
              vim-svelte
              rust-vim
              vim-markdown
              tabular # used by vim-markdown
              mkdir-nvim
            ];
            opt = [ ];
          };
        };
      };
    })
  ];
};
}
