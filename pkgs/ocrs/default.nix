{ lib, fetchFromGitHub, rustPlatform }:
let
  version = "v0.10.3";
in rustPlatform.buildRustPackage {
  pname = "ocrs-cli";
  inherit version;

  src = fetchFromGitHub {
    owner = "robertknight";
    repo = "ocrs";
    rev = "ocrs-cli-${version}";
    hash = "sha256-WLzaCWojaa8WPtxg3D47HNjhpQYurU6Tg/Y0WYQJbXs=";
  };

  cargoHash = "sha256-E2VrNF28mfRfLHizRkRZRFPJO503extv8EBq9b1KmKw=";

  meta = with lib; {
    description = "Rust CLI tool for OCR";
    homepage = url;
    license = licenses.mit;
    maintainers = with maintainers; [ ppom ];
  };
}
