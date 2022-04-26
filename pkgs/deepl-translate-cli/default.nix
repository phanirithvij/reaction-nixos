{ lib, fetchFromGitHub, buildGoModule }:
buildGoModule rec {
  pname = "deepl-translate-cli";
  version = "0.0.12";

  src = fetchFromGitHub {
    owner = "Omochice";
    repo = "deepl-translate-cli";
    rev = "v${version}";
    sha256 = "sha256-ZpndmXnzgL92XtOnFfmigmsg9tiWqO3mwfedzAs3l/A=";
  };

  vendorSha256 = "sha256-/3xZkcJxwoEJJYurd4VZLPvlQTWdsqLrq++ks8vrrYc=";

  meta = with lib; {
    description = " Unofficial deepl client on CLI ";
    homepage = "https://github.com/Omochice/deepl-translate-cli";
    license = licenses.mit;
    maintainers = with maintainers; [ ppom ];
    platforms = platforms.linux ++ platforms.darwin;
  };
}
