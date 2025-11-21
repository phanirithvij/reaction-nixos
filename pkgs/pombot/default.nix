{ lib, fetchFromGitLab, rustPlatform }:
rustPlatform.buildRustPackage {
  pname = "reaction";
  version = "unstable-2025-11-21";

  src = fetchFromGitLab {
    domain = "framagit.org";
    owner = "ppom";
    repo = "pombot";
    rev = "b6c273cf63ebe70c7d1ddab6e40ec6e349136336";
    sha256 = "sha256-CNwb+Dhc02lyfYDC3zbzr8LmNM42lsp95BKQwrceLf8=";
  };

  cargoHash = "sha256-hM1Y5ITY7ijugghRw6HkacvzO6Y4VwwLG57w+RfhjKk=";

  meta = with lib; {
    description = "Pombot";
    homepage = "https://framagit.org/ppom/pombot";
    license = licenses.agpl3Plus;
    mainProgram = "pombot";
    maintainers = with maintainers; [ ppom ];
    platforms = platforms.unix;
  };
}
