{ buildGoModule, fetchFromGitLab }:
let
  pname = "cospend-balance";
  version = "v1.1";
in buildGoModule {
  inherit pname version;

  src = fetchFromGitLab {
    domain = "framagit.org";
    owner = "ppom";
    repo = pname;
    rev = version;
    sha256 = "sha256-QHHhpnJVhFLRLxzKo+SgTa0iyKDCsDJLhFJ/Ijlo9es=";
  };

  vendorHash = "sha256-g+yaVIx4jxpAQ/+WrGKxhVeliYx7nLQe/zsGpxV4Fn4=";
}
