{ buildGoModule, fetchFromGitLab }:
let
  pname = "reaction";
  version = "v0.1";
in buildGoModule {
  inherit pname version;

  src = fetchFromGitLab {
    domain = "framagit.org";
    owner = "ppom";
    repo = pname;
    rev = version;
    sha256 = "sha256-vZPiWCL4pMgnBjqSvLJ759kbU5cFUS5ZO5chgK0x3E4=";
  };

  vendorHash = "sha256-g+yaVIx4jxpAQ/+WrGKxhVeliYx7nLQe/zsGpxV4Fn4=";
}
