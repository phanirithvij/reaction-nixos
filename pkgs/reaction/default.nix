{
stdenv
, linkFarm
, fetchFromGitLab
, rustPlatform
}:
let
  pname = "reaction";
  # version = "v2.0.0-rc1";
  version = "7c3116b7c901ca2b9bd39264faba25128ca6c45e";
  src = fetchFromGitLab {
    domain = "framagit.org";
    owner = "ppom";
    repo = pname;
    rev = version;
    sha256 = "sha256-oxVeCss+Y/G2HnDB8teWPe2FNdXbkQBysZbJ1aXH/LU=";
  };
  reaction = rustPlatform.buildRustPackage {
    inherit pname version src;
    cargoSha256 = "sha256-LX8lI4GZpH62JCgK7brmI8KpM1aAFEoTxC7sBTiswMk=";
  };
  ip46tables = stdenv.mkDerivation {
    inherit version src;
    pname = "ip46tables";
    buildPhase = ''
      gcc helpers_c/ip46tables.c -o ip46tables
    '';
    installPhase = ''
      mkdir -p $out/bin
      cp ip46tables $out/bin
    '';
  };
in linkFarm "reaction" [
  { name = "bin/reaction"; path = "${reaction}/bin/reaction"; }
  { name = "bin/ip46tables"; path = "${ip46tables}/bin/ip46tables"; }
]
