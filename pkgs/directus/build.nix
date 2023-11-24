{
  pkgs ? import <nixpkgs-unstable> {},
  system ? builtins.currentSystem,
} :
{
  directus = pkgs.callPackage ./default.nix {};
}
