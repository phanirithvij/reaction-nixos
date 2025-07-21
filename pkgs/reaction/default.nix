{ lib, fetchFromGitLab, rustPlatform }:
let
  version = "v2.1.2";
in rustPlatform.buildRustPackage {
  pname = "reaction";
  inherit version;

  src = fetchFromGitLab {
    domain = "framagit.org";
    owner = "ppom";
    repo = "reaction";
    rev = version;
    sha256 = "sha256-lcd0yY8o5eGa1bP5WsA9K/K7gtjRVorS/Rm0bno0AOY=";
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
