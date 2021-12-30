{ stdenv
, lib
, bash
, mkYarnPackage
# , appendPatch
, musicDir ? null
}:

mkYarnPackage {
  pname = "rzw";
  version = "unstable-2021-05-24";

  src = fetchGit {
    url = "https://framagit.org/ppom/rzw";
    rev = "bd8d081f0cbbf46ef81d33e3456bfbc41378d331";
  };

  yarnNix = ./deps.nix;

  installPhase = ''
    mkdir $out
    yarn --offline --frozen-lockfile build
    cp -r deps/RuleZeWorld/public $out/
    cp -r deps/RuleZeWorld/misc   $out/
  '' + (if (musicDir != null) then ''
    ln -s ${musicDir} $out/public/music
  '' else ''
    mkdir $out/public/music
  '');

  distPhase = "echo [no distPhase]";

  meta = with lib; {
    homepage = "https://framagit.org/ppom/rzw";
    description = "Simple app allowing to monitor menstruations";
    license = licenses.gpl3;
    platforms = platforms.unix;
  };
}
