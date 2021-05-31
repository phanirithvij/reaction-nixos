{ buildGoPackage, fetchFromGitHub }:
buildGoPackage rec {
  pname = "vtt2srt";
  version = "2016-11-07";
  goPackagePath =  "github.com/rzumer/VTT2SRT";
  src = fetchFromGitHub {
    owner = "rzumer";
    repo = "VTT2SRT";
    rev = "090faa996d377cda18f2e41154b23c9d9e4e5864";
    sha256 = "0hn5dpis4y343lz6dmnvdffgx1xwk2f42k7l1y9ydqdxqb7i4igm";
  };
  goDeps = ./deps.nix;
}
