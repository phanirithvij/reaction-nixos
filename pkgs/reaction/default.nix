{ buildGoModule, fetchFromGitLab }:
let
  pname = "reaction";
  version = "v0.2";
in buildGoModule {
  inherit pname version;

  src = fetchFromGitLab {
    domain = "framagit.org";
    owner = "ppom";
    repo = pname;
    rev = version;
    sha256 = "sha256-Onj/KdJwe0ulEGjiYA4GyKKZg6OA8UXujOQqHeHDJ+U=";
  };

  vendorHash = "sha256-g+yaVIx4jxpAQ/+WrGKxhVeliYx7nLQe/zsGpxV4Fn4=";
}
