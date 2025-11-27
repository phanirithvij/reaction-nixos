{
  lib,
  fetchFromGitLab,
  rustPlatform,
}:
rustPlatform.buildRustPackage {
  pname = "reaction";
  version = "unstable-2025-11-21";

  src = fetchFromGitLab {
    domain = "framagit.org";
    owner = "ppom";
    repo = "pombot";
    rev = "b6853d0e54b25af50d1258530ea480287bf276b6";
    sha256 = "sha256-GYLtUSbuzJWLDQkyaaPnZEYvOSQs1FRlfVgrsNLaqEk=";
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
