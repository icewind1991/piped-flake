{ src, stdenv, lib, gradle, runtimeShell, jdk
, extraPatches ? []
}:

let
  pname = "piped-backend";

  inherit src;

  jar = let self = stdenv.mkDerivation {

    name = "${pname}-jar";

    inherit src;

    nativeBuildInputs = [ gradle ];

    patches = [ ./0001-run-matrix-loop-conditionally.patch ] ++ extraPatches;

    postPatch = ''
      substituteInPlace build.gradle --replace-fail \
        "implementation 'com.github.FireMasterK:NewPipeExtractor:92809cedefd89ce68bc4de8763e9d5f2760f5899'" \
        "implementation 'com.github.AudricV:NewPipeExtractor:17d6e5c5afb7e30506c5f809e96d68ef43f2f31c'"
    '';

    mitmCache = gradle.fetchDeps {
      pkg = self;
      data = ./deps.json;
    };
    gradleBuildTask = "shadowJar";

    postInstall = ''
      mv build/libs/piped-1.0-all.jar $out
    '';
  }; in self;

in

stdenv.mkDerivation {

  name = pname;

  dontBuild = true;

  unpackPhase = "true";

  installPhase = ''
    mkdir -p $out/bin
    echo "#!${runtimeShell}" >> $out/bin/piped-backend
    echo "${jdk}/bin/java -server --enable-preview -jar ${jar}" >> $out/bin/piped-backend
    chmod u+x $out/bin/piped-backend
  '';

  passthru = {
    inherit jar;
  };

  meta = {
    homepage = "https://github.com/TeamPiped/piped-backend";
    license = lib.licenses.agpl3Only;
    sourceProvenance = with lib.sourceTypes; [ fromSource binaryBytecode ];
  };

}
