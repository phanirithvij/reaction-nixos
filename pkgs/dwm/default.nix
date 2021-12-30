{ stdenv, lib, libX11, libXinerama, libXft }:
#{ stdenv, fetchgit, libX11, libXinerama, libXft, patches ? [], conf ? null }:

stdenv.mkDerivation {
  name = "dwm-HEAD";

  src = fetchGit {
    url = "https://framagit.org/ppom/dwm.git";
    rev = "3f0d7f75614df2af90946c5b7c377a5fe303eae2";
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
