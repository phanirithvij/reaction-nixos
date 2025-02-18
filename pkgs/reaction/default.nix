{ lib, fetchFromGitLab, rustPlatform }:
rustPlatform.buildRustPackage {
  pname = "reaction";
  version = "unstable-2025-02-17";
  # version = "v2.0.0-rc1";

  src = fetchFromGitLab {
    domain = "framagit.org";
    owner = "ppom";
    repo = "reaction";
    rev =  "a238c7411f042955b6062b05c6a6bd24d2f682ed";
    sha256 = "sha256-vb0/qo7mKDKiGI2t8GW3ztk7EgdEV+oia5Hr2vL8fg0=";
  };

  cargoHash = "sha256-FVp54abv7+o7t2UkoOdR13uy31AObK8IRAD6Lm/ZZs0=";

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
