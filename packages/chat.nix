{ stdenv, lib, jdk11, bash }:

stdenv.mkDerivation {
  name = "javachat";

  src = fetchGit {
    url = "https://gitlab.utc.fr/ppompean/ai16p21.git";
    rev = "b502c1d057552bb6222e8e0f92bc2b71efcefbe6";
  };

  buildPhase = ''
    mkdir $out/{,bin,lib}
    shopt -s globstar
    ${jdk11}/bin/javac -encoding UTF-8 -d $out/lib src/**/*.java
  '';

  installPhase = ''
    # server script
    cat > $out/bin/chatserver << EOF
    #!${bash}/bin/bash
    cd $out/lib/
    ${jdk11}/bin/java -Djava.net.preferIPv4Stack=true server.MainServer
    EOF

    # client script
    cat > $out/bin/chatclient << EOF
    #!${bash}/bin/bash
    cd $out/lib/
    ${jdk11}/bin/java client.MainClient
    EOF

    chmod +x $out/bin/{chatserver,chatclient}
  '';

  meta = with lib; {
    homepage = "https://gitlab.utc.fr/ppompean/ai16p21.git";
    description = "Mini-chat application written in java for educational purposes";
    license = licenses.mit;
    platforms = platforms.unix;
  };
}
