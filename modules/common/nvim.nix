{ lib, config, pkgs, ... }:

with config.ppom;
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
          '' + lib.optionalString isDesktop ''
          '';
          packages.myVimPackage = with pkgs.vimPlugins; {
            start = [
              vim-nix
              vim-commentary
              vim-surround
              vim-repeat
              vim-fugitive
              # gruvbox
              (super.vimPlugins.gruvbox.overrideAttrs (oldAttrs: {
                patches = [ ./true_black_gruvbox.patch ];
              }))
            ] ++ lib.optionals isDesktop [
            ];
            opt = [ ];
          };
	};
      };
    })
  ];
}
