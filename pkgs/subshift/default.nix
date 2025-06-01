{ lib, fetchFromGitLab, rustPlatform }:

rustPlatform.buildRustPackage {
  pname = "subshift";
  version = "unstable-2023-01-07";

  src = fetchFromGitLab {
    domain = "framagit.org";
    owner = "ppom";
    repo = "subshift";
    rev = "d223d255ed1de4a6577b34c0f8fd9b8bc4bcc41b";
    sha256 = "sha256-pCu9mM+wrNFYzNgUk2LLnIr+6IURoNsJ2Kx4SKVcTWQ=";
  };

  cargoHash = "sha256-qiaV1e127ZAvi0RDqFQxU7saRKerXt8MIwWjY4QxOCo=";

  outputs = [ "out" ];

  meta = with lib; {
    description = "Subtitle editor on the command line";
    homepage = url;
    license = licenses.agpl3Plus;
    maintainers = with maintainers; [ ppom ];
  };
}
