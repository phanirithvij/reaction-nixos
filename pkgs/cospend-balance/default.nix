{ buildGoModule, fetchFromGitLab }:
let
  pname = "cospend-balance";
  version = "v1.3";
in
buildGoModule {
  inherit pname version;

  src = fetchFromGitLab {
    domain = "framagit.org";
    owner = "ppom";
    repo = pname;
    rev = version;
    sha256 = "sha256-p7PH0UI8Rrcv9PQYj5PkH8zmGgYwRSM0ll67gRgUIJM=";
  };

  vendorHash = "sha256-g+yaVIx4jxpAQ/+WrGKxhVeliYx7nLQe/zsGpxV4Fn4=";
}
