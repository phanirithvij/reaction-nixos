{
stdenv
, linkFarm
, buildGoModule
, fetchFromGitLab
}:
let
  pname = "reaction";
  version = "v1.1.0";
  src = fetchFromGitLab {
    domain = "framagit.org";
    owner = "ppom";
    repo = pname;
    rev = version;
    sha256 = "sha256-SSSd15nS6AgP9akKscvuUL4t5QRiMdgVfObX5BZOH3Q=";
  };
  reaction = buildGoModule {
    inherit pname version src;

    vendorHash = "sha256-THUIoWFzkqaTofwH4clBgsmtUlLS9WIB2xjqW7vkhpg=";
  };
  ip46tables = stdenv.mkDerivation {
    inherit version src;
    pname = "ip46tables";
    buildPhase = ''
      gcc ip46tables.d/ip46tables.c -o ip46tables
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
