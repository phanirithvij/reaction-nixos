{
stdenv
, linkFarm
, fetchFromGitLab
, rustPlatform
}:
let
  pname = "reaction";
  # version = "v2.0.0-rc1";
  version = "21e2cf67dc1e04c748db209b3f68a143f776cdcd";
  src = fetchFromGitLab {
    domain = "framagit.org";
    owner = "ppom";
    repo = pname;
    rev = version;
    sha256 = "sha256-o4YCACcbtft//jf7bcPmg/h7z2roXqVeNRuDA4t+v+M=";
  };
  reaction = rustPlatform.buildRustPackage {
    inherit pname version src;
    cargoSha256 = "sha256-KgYsiSVTLyvEbnSv3z2v+SwVgzHZL5FjJzbFoLzOmOs=";
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
