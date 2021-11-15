{ lib, fetchFromGitHub }:
let
  pkgs = import <nixpkgs> {
    overlays = [
      (self: super: {
        buildGoApplication = super.callPackage ./builder { };
      })
    ];
  };
  protocol = "https";
  hoster = "github.com";
  owner = "ZizzyDizzyMC";
  repo = "linx-server";
in
pkgs.buildGoApplication {
  pname = repo;
  version = "2021-10-10";

  src = fetchFromGitHub {
    owner = owner;
    repo = repo;
    rev = "a327bb8dbe55bbdd0ef5e2b6178d9296bf476937";
    sha256 = "0hbvwp4r8h99ibia0zyzf61aymc2j52mh27x1iz71shwsim7jyhb";
  };

  modules = ./gomod2nix.toml;

  patches = [ ./block_tests.patch ];

  postInstall = ''
    mkdir -p $out/share/linx-server
    cp -r static templates $out/share/linx-server
  '';

  meta = {
    description = "Self-hosted file/media sharing website";
    homepage = "${protocol}://${hoster}/${owner}/${repo}";
  };
}
