{
  src,
  lib,
  buildNpmPackage,
  fetchPnpmDeps,
  pnpmConfigHook,
  pnpm,
  fetchurl,
  writeScript,
}: let
  pname = "pipedfrontend";

  version = "0.0.1";

  doPnpmDeps = hash:
    fetchPnpmDeps {
      fetcherVersion = 3;
      inherit pname version src hash;
    };

  pnpmDeps = doPnpmDeps (builtins.fromJSON (builtins.readFile ./npmDepsHash.json));

  fonts = builtins.mapAttrs (url: hash: fetchurl {inherit url hash;}) (builtins.fromJSON (builtins.readFile ./fonts.json));
  copyFonts = builtins.concatStringsSep "\n" (lib.mapAttrsToList (
      url: font: let
        fontPath = "dist/fonts/" + (builtins.substring (builtins.stringLength "https://fonts.gstatic.com/") (-1) url);
      in ''
        mkdir -p $(dirname ${fontPath})
        cp ${font} ${fontPath}
      ''
    )
    fonts);
in
  buildNpmPackage {
    inherit pname pnpmDeps src version;

    npmConfigHook = pnpmConfigHook;

    npmDeps = pnpmDeps;

    postBuild = ''
      echo "postBuild"
      mkdir -p dist/fonts

      ${copyFonts}

      sed -i "s#https://fonts.gstatic.com#/fonts#g" dist/assets/*
      ls -l dist/fonts/
    '';

    installPhase = ''
      cp dist $out -r
    '';

    nativeBuildInputs = [pnpm];

    passthru = {
      hashUpdate = doPnpmDeps "";
      fonts = writeScript "update-font-hashes" ''
        #!/usr/bin/env bash

        tmp=$(mktemp -d)
        cp -r "${src}" "$tmp/src"
        chmod -R 750 $tmp/src
        (
            cd "$tmp/src"
            pnpm install
            echo "extracting"
            bash ${./extract-font-hashes.sh} > fonts.json
            cat fonts.json
        )
        cp "$tmp/src/fonts.json" "piped-frontend/fonts.json"
        rm -fr "$tmp"
      '';
    };

    meta = {
      homepage = "https://github.com/TeamPiped/piped";
      license = lib.licenses.agpl3Only;
      sourceProvenance = with lib.sourceTypes; [fromSource];
    };
  }
