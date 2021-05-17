{ lib, config, pkgs, ... }:
{
  imports = [ ppom.nix ];

  environment.systemPackages = [
    neovim
    python38Packages.pynvim
  ] ++ if ppom.isDesktop then [
    black
    ccls
  ] else [];

  nixpkgs.overlays = [
    (self: super: {
      neovim = super.neovim.override {
        # nvim aliases
        viAlias = true;
        vimAlias = true;
        configure = {
          customRC = ''
            set number termguicolors
            colorscheme gruvbox
            let g:mapleader = " "
            nnoremap <leader>h noh<CR>
          '';
          packages.myVimPackage = with pkgs.vimPlugins; {
            start = [
              vim-nix
              # gruvbox # TODO override the "black" here 😎
              (super.vimPlugins.gruvbox.overrideAttrs (oldAttrs: {
                patches = [ ./true_black_gruvbox.patch ];
              }))
              vim-commentary
              vim-surround
              vim-repeat
              vim-fugitive
            ];
            opt = [ ];
          };
	};
      };
    })
  ];
}
