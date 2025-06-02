{ lib, fetchFromGitLab, rustPlatform }:
rustPlatform.buildRustPackage {
  pname = "reaction";
  version = "unstable-2025-06-01";
  # version = "v2.0.0-rc1";

  src = fetchFromGitLab {
    domain = "framagit.org";
    owner = "ppom";
    repo = "reaction";
    rev =  "bc078471a93692815f35d96d76a626b1e7ef955d";
    sha256 = "sha256-sP3Q9O0xoTjh+Pt8M9FT12lgN879LlekqMoA+PbkE1I=";
  };

  cargoHash = "sha256-G4Uxr90NnrDu2x0IbMnU2K89cF+wwTnlFTqlrc5+vjA=";

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
