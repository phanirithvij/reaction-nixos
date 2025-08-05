{ lib, fetchFromGitLab, rustPlatform }:
let
  version = "v2.2.0-unstable";
in rustPlatform.buildRustPackage {
  pname = "reaction";
  inherit version;

  src = fetchFromGitLab {
    domain = "framagit.org";
    owner = "ppom";
    repo = "reaction";
    rev = "56e4d778546c17f298fe171c8f9ab37f2210907d";
    sha256 = "sha256-n6O9Xk5OoAG5ytmXxWfWdg8augkIHHWfWA0D2g0eT6k=";
  };

  cargoHash = "sha256-ZRTgzVz8ia763cMBx9U1NIy9W6gDUVhwNr6wDqU1Ulo=";

  postBuild = ''
    $CC helpers_c/ip46tables.c -o ip46tables
    $CC helpers_c/nft46.c -o nft46
  '';

  postInstall = ''
    cp ip46tables nft46 $out/bin
  '';

  meta = with lib; {
    description = "Scan logs and take action: an alternative to fail2ban";
    homepage = "https://framagit.org/ppom/reaction";
    changelog = "https://framagit.org/ppom/reaction/-/releases/v${version}";
    license = licenses.agpl3Plus;
    mainProgram = "reaction";
    maintainers = with maintainers; [ ppom ];
    platforms = platforms.unix;
  };
}
