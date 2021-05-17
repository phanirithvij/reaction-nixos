{ lib, config, pkgs, ... }:
{
  imports = [ ./ppom.nix ];

  environment.systemPackages = [
    pkgs.neovim
    pkgs.python38Packages.pynvim
  ] ++ lib.optionals config.ppom.isDesktop [
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
        # nvim aliases
        viAlias = true;
        vimAlias = true;
        configure = {
          customRC = ''
            set number termguicolors
            let g:mapleader = " "
            nnoremap <leader>h noh<CR>
          '' + lib.optionalString config.ppom.isDesktop ''
            colorscheme gruvbox
          '';
          packages.myVimPackage = with pkgs.vimPlugins; {
            start = [
              vim-nix
              vim-commentary
              vim-surround
              vim-repeat
              vim-fugitive
            ] ++ lib.optionals config.ppom.isDesktop [
              # gruvbox # TODO override the "black" here 😎
              (super.vimPlugins.gruvbox.overrideAttrs (oldAttrs: {
                patches = [ ./true_black_gruvbox.patch ];
              }))
            ];
            opt = [ ];
          };
	};
      };
    })
  ];
}
