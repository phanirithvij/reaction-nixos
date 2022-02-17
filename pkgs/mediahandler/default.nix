{ stdenv, lib, bash, python3 }:

let
  finePython = python3.withPackages (ps: [ ps.dbus-python ]);
in stdenv.mkDerivation {
  pname = "mediahandler";
  version= "2021-12-15";

  src = fetchGit {
    url = "https://framagit.org/ppom/desktop-play-pause.git";
    rev = "a03159da888d91a69b8e1f4d1b64b89e43b453b8";
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
