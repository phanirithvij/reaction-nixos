{ stdenv
, lib
, bash
, mkYarnPackage
# , appendPatch
, musicDir ? null
}:

mkYarnPackage {
  pname = "rzw";
  version = "unstable-2020-08-11";

  src = fetchGit {
    url = "https://framagit.org/ppom/rzw";
    rev = "36ca56f4d2f47580444bbac6cc544ae27fd264e5";
  };

  patches = [ ./env.patch ];

  yarnNix = ./deps.nix;

  installPhase = ''
    yarn --offline --frozen-lockfile build
    cp -r deps/RuleZeWorld/public $out
  '' + (if (musicDir != null) then ''
    ln -s ${musicDir} $out/music
  '' else ''
    mkdir $out/music
  '');

  distPhase = "echo [no distPhase]";

  meta = with lib; {
    homepage = "https://framagit.org/ppom/rzw";
    description = "Simple app allowing to monitor menstruations";
    license = licenses.gpl3;
    platforms = platforms.unix;
  };
}
