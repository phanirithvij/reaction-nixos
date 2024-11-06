{
stdenv
, linkFarm
, fetchFromGitLab
, rustPlatform
}:
let
  pname = "reaction";
  # version = "v2.0.0-rc1";
  version = "b747e52e94e5698090ddb924490eaa4318e127eb";
  src = fetchFromGitLab {
    domain = "framagit.org";
    owner = "ppom";
    repo = pname;
    rev = version;
    sha256 = "sha256-B+jxity7ztbLAoUYu3MXLlyvKaDCY5bO7WG6/59eQeQ=";
  };
  reaction = rustPlatform.buildRustPackage {
    inherit pname version src;
    cargoSha256 = "sha256-gA4SZDA7yJQM7RWpowI12nvUnbKVA0Y2XSqlhJ4fewQ=";
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
