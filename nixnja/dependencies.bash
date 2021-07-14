# found here: https://primeos.github.io/nixos-slides/#/18
# and adapted
nix-store -q --graph $(nix-store --realise $(nix-instantiate -E "with import <nixpkgs> {}; callPackage ./default.nix {}")) | dot -Tpdf > ~/dependencies.pdf

