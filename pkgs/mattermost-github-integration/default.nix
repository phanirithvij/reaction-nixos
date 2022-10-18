{ lib, stdenv, fetchFromGitHub, python3, runtimeShell, configPath ? "/etc/mattermostgithub/config.py" }:
let 
  pp = python3.withPackages(ps: with ps; [ requests pillow gunicorn flask ]);
in stdenv.mkDerivation {
  pname = "mattermost-github-integration";
  version = "unstable-2022-01-13";

  src = fetchFromGitHub {
    owner = "softdevteam";
    repo = "mattermost-github-integration";
    rev = "c5ac79b5412992c227c7f61d87041fa9eb94e45f";
    sha256 = "sha256-uE1Kj6CEMLL6II8580Yfu0Kag7e6d9iABbE8yRXzTEM=";
  };

  # TODO upstream an option in config that does this
  patches = [ ./verify-ssl.patch ];

  installPhase = ''
    mkdir $out $out/bin
    cp -r . $out/src
    chmod +w $out/src $out/src/mattermostgithub
    ln -s ${configPath} $out/src/mattermostgithub/config.py
    # touch $out/src/mattermostgithub/config.py
    cat > $out/bin/mattermostgithub <<EOF
    #!${runtimeShell}
    ${pp}/bin/python $out/src/server.py
    EOF
    chmod +x $out/bin/mattermostgithub
  '';

  meta = with lib; {
    description = "GitHub integration for Mattermost";
    homepage = "https://github.com/softdevteam/mattermost-github-integration";
    license = licenses.mit;
    maintainers = with maintainers; [ ppom ];
    platforms = platforms.linux ++ platforms.darwin;
  };
}
