{
  lib,
  stdenv,
  fetchFromGitLab,
  jdk11,
  makeDesktopItem,
  makeWrapper,
}:
let
  pname = "soweli";
  version = "unstable-2022-06-22";

  src = fetchFromGitLab {
    domain = "framagit.org";
    owner = "ppom";
    repo = "soweli";
    rev = "865b1c4206f65334d03150b12c2e7cd984625749";
    sha256 = "sha256-rUB2FLrs9swzDzVh+u6Vm8wBEdFIU2+l96SWXO/oGnQ=";
  };

  desktopItem = makeDesktopItem {
    name = "soweli";
    exec = "soweli";
    icon = "soweli";
    comment = "A Zelda-like game";
    desktopName = "Soweli";
    mimeTypes = [
      "application/java"
      "application/java-vm"
      "application/java-archive"
    ];
    categories = [ "Game" ];
  };

in
stdenv.mkDerivation rec {
  inherit pname src version;

  nativeBuildInputs = [
    jdk11
    makeWrapper
  ];

  buildPhase = ''
    runHook preBuild

    mkdir -p $out/lib
    rm -r src/tests
    javac -encoding utf8 -d $out/lib $(find ./src -name "*.java")

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/{${pname},icons/hicolor/46x46/apps}
    cp logo.png $out/share/icons/hicolor/46x46/apps/soweli.png
    mkdir -p $out/src/vue
    cp -r src $out/

    runHook postInstall
  '';

  postFixup = ''
    mkdir -p $out/bin
    makeWrapper ${jdk11}/bin/java $out/bin/${pname} --add-flags "-cp $out/lib application.Main" --chdir $out
  '';

  desktopItems = [ desktopItem ];

  meta = with lib; {
    description = "A Zelda-like game";
    homepage = "https://framagit.org/ppom/soweli";
    license = licenses.gpl3;
    maintainers = with maintainers; [ ppom ];
    platforms = platforms.all;
  };
}
