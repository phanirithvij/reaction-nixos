{ stdenv, lib, bash, python3 }:

let
  finePython = python3.withPackages (ps: [ ps.dbus-python ]);
in stdenv.mkDerivation {
  pname = "mediahandler";
  version= "2021-12-15";

  src = fetchGit {
    url = "https://framagit.org/ppom/desktop-play-pause.git";
    rev = "d14c45dbdba8f07d905c4f16b01f2d196fb4f389";
  };

  installPhase = ''
    mkdir $out/{,bin,lib}
    cp media.py metadata.py $out/lib/

    cat > $out/bin/mediahandler << EOF
    #!${bash}/bin/bash
    exec ${finePython}/bin/python $out/lib/media.py "\$@"
    EOF

    cat > $out/bin/mediastatus << EOF
    #!${bash}/bin/bash
    exec ${finePython}/bin/python $out/lib/metadata.py "\$@"
    EOF

    chmod +x $out/bin/{mediahandler,mediastatus}
  '';

  meta = with lib; {
    homepage = "https://framagit.org/ppom/desktop-play-pause";
    description = "Media play/pause/previous/next handler ⏮ ⏯️ ⏭️";
    license = licenses.mit;
    platforms = platforms.unix;
  };
}
