{
  lib,
  config,
  pkgs,
  ...
}:
let
  # unstable = import <nixos-unstable> {
  # config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) (map lib.getName [ pkgs.vscode ]);
  # };

in
{
  options.ppom.helix = {
    enable = lib.mkEnableOption "enable ppom git";
    steroids = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "More LSP servers";
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

  config =
    let
      cfg = config.ppom.helix;
    in
    lib.mkIf cfg.enable {

      environment = {
        variables = {
          EDITOR = "hx";
          VISUAL = "hx";
        };
        systemPackages =
          let
            nodes = pkgs.nodePackages;
          in
          [
            pkgs.helix
            # (pkgs.stdenv.mkDerivation {
            #   buildPhase = ''
            #     makeWrapper ''$out/bin/vi ${pkgs.helix}
            #   '';
            # })
            (pkgs.runCommandNoCCLocal "vi-helix-alias" { } ''
              mkdir -p $out/bin
              ln -s ${pkgs.helix}/bin/hx $out/bin/vi
            '')
          ]
          ++ lib.optionals cfg.enableNixd [
            pkgs.nixd
          ]
          ++ lib.optionals cfg.enableGo [
            pkgs.gopls
          ]
          ++ lib.optionals cfg.steroids [
            # pkgs.nodejs
            # pkgs.pylizer # not packaged yet
            nodes."@tailwindcss/language-server"
            nodes.bash-language-server
            # nodes.svelte-language-server
            # nodes.typescript-language-server
            # nodes.vls # vue-language-server
            pkgs.ccls
            pkgs.gopls
            # pkgs.jdt-language-server # java
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
    };
}
