{ stdenv, lib, bash, python3 }:

let
  finePython = python3.withPackages (ps: [ ps.dbus-python ]);
in stdenv.mkDerivation {
  pname = "mediahandler";
  version= "2021-12-15";

  src = fetchGit {
    url = "https://framagit.org/ppom/desktop-play-pause.git";
    rev = "68d250827d9e4eb867406fdedc8902caf04e1455";
  };

  installPhase = ''
    mkdir $out/{,bin,lib}
    cp media.py $out/lib/
    cat > $out/bin/mediahandler << EOF
    #!${bash}/bin/bash
    exec ${finePython}/bin/python $out/lib/media.py "\$@"
    EOF

    chmod +x $out/bin/mediahandler
  '';

  meta = with lib; {
    homepage = "https://framagit.org/ppom/desktop-play-pause";
    description = "Media play/pause/previous/next handler ⏮ ⏯️ ⏭️";
    license = licenses.mit;
    platforms = platforms.unix;
  };
}
