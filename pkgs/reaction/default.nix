{ lib, fetchFromGitLab, rustPlatform }:
let
  version = "v2.2.1";
in rustPlatform.buildRustPackage {
  pname = "reaction";
  inherit version;

  src = fetchFromGitLab {
    domain = "framagit.org";
    owner = "ppom";
    repo = "reaction";
    rev = version;
    sha256 = "sha256-81i0bkrf86adQWxeZgIoZp/zQQbRJwPqQqZci0ANRFw=";
  };

  cargoHash = "sha256-Bf9XmlY0IMPY4Convftd0Hv8mQbYoiE8WrkkAeaS6Z8=";

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
