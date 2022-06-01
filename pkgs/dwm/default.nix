{ stdenv, lib, libX11, libXinerama, libXft }:
#{ stdenv, fetchgit, libX11, libXinerama, libXft, patches ? [], conf ? null }:

stdenv.mkDerivation {
  name = "dwm-HEAD";

  src = fetchGit {
    url = "https://framagit.org/ppom/dwm.git";
    rev = "f7d4f421e6b3d122b509cf20d601fda458c5de8b";
  };

  buildInputs = [ libX11 libXinerama libXft ];

  prePatch = ''sed -i "s@/usr/local@$out@" config.mk'';

  buildPhase = "make";

  meta = with lib; {
    homepage = "https://suckless.org/";
    description = "Dynamic window manager for X, version with ppom's patches";
    license = licenses.mit;
    platforms = platforms.unix;
  };
}
