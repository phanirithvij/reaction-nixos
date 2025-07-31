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
    rev = "7acd15ac990c86f28f97d399e5805689235cd73c";
    sha256 = "sha256-bz11j7BltyGeZusfvrK0aIfcLyBOizRVYH+aioVuweI=";
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
