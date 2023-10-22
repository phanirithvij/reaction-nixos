{
stdenv
, linkFarm
, buildGoModule
, fetchFromGitLab
}:
let
  pname = "reaction";
  version = "v0.4";
  src = fetchFromGitLab {
    domain = "framagit.org";
    owner = "ppom";
    repo = pname;
    rev = version;
    sha256 = "sha256-sRum8r+zFCF0k1EFkGFOR2EqSE6O/B5xiU7nJP518YQ=";
  };
  reaction = buildGoModule {
    inherit pname version src;

    vendorHash = "sha256-THUIoWFzkqaTofwH4clBgsmtUlLS9WIB2xjqW7vkhpg=";
  };
  ip46tables = stdenv.mkDerivation {
    inherit pname version src;
    buildPhase = ''
      make ip46tables
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
