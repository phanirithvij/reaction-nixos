{ buildGoModule, fetchFromGitLab }:
let
  pname = "cospend-balance";
  version = "v1.2";
in buildGoModule {
  inherit pname version;

  src = fetchFromGitLab {
    domain = "framagit.org";
    owner = "ppom";
    repo = pname;
    rev = version;
    sha256 = "sha256-57CGNLYsrG2CGWBIfzPD0f1ARuQ/qbApuG9UqCoTbvo=";
  };

  vendorHash = "sha256-g+yaVIx4jxpAQ/+WrGKxhVeliYx7nLQe/zsGpxV4Fn4=";
}
