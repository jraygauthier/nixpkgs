{ lib, stdenv, fetchurl, vscode-utils, extractNuGet
, icu, curl, openssl, lttng-ust, autoPatchelfHook
, python3, musl
, pythonUseFixed ? false       # When `true`, the python default setting will be fixed to specified.
                               # Use version from `PATH` for default setting otherwise.
                               # Defaults to `false` as we expect it to be project specific most of the time.
, ctagsUseFixed ? true, ctags  # When `true`, the ctags default setting will be fixed to specified.
                               # Use version from `PATH` for default setting otherwise.
                               # Defaults to `true` as usually not defined on a per projet basis.
}:

assert ctagsUseFixed -> null != ctags;

let
  pythonDefaultsTo = if pythonUseFixed then "${python3}/bin/python" else "python";
  ctagsDefaultsTo = if ctagsUseFixed then "${ctags}/bin/ctags" else "ctags";

  rtDepsSrcsFromJson = builtins.fromJSON (builtins.readFile ./rt-deps-bin-srcs.json);
  rtDepsBinSrcs = builtins.mapAttrs (k: v:
      let
        # E.g: "Python-Language-Server__x86_64-linux"
        kSplit = builtins.split "(__)" k;
        name = builtins.elemAt kSplit 0;
        system = builtins.elemAt kSplit 2;
      in
      {
        inherit name system;
        inherit (v) version;
        src = fetchurl {
          urls = v.urls;
          inherit (v) sha256;
        };
      }
    )
    rtDepsSrcsFromJson;

  rtDepBinSrcByName = bSrcName:
    rtDepsBinSrcs."${bSrcName}__${stdenv.targetPlatform.system}";

  languageServer = extractNuGet (rtDepBinSrcByName "Python-Language-Server");
in vscode-utils.buildVscodeMarketplaceExtension rec {
  mktplcRef = {
    name = "python";
    publisher = "ms-python";
    version = "2021.9.1246542782";
  };

  vsix = fetchurl {
    name = "${mktplcRef.publisher}-${mktplcRef.name}.zip";
    url = "https://github.com/microsoft/vscode-python/releases/download/${mktplcRef.version}/ms-python-release.vsix";
    sha256 = "sha256:105vj20749bck6ijdlf7hsg5nb82bi5pklf80l1s7fn4ajr2yk02";
  };

  buildInputs = [
    icu
    curl
    openssl
    lttng-ust
    musl
  ];

  nativeBuildInputs = [
    autoPatchelfHook
    python3.pkgs.wrapPython
  ];

  pythonPath = with python3.pkgs; [
    setuptools
  ];

  postPatch = ''
    # Patch `packages.json` so that nix's *python* is used as default value for `python.pythonPath`.
    substituteInPlace "./package.json" \
      --replace "\"default\": \"python\"" "\"default\": \"${pythonDefaultsTo}\""

    # Patch `packages.json` so that nix's *ctags* is used as default value for `python.workspaceSymbols.ctagsPath`.
    substituteInPlace "./package.json" \
      --replace "\"default\": \"ctags\"" "\"default\": \"${ctagsDefaultsTo}\""
  '';

  postInstall = ''
    mkdir -p "$out/$installPrefix/languageServer.${languageServer.version}"
    cp -R --no-preserve=ownership ${languageServer}/* "$out/$installPrefix/languageServer.${languageServer.version}"
    chmod -R +wx "$out/$installPrefix/languageServer.${languageServer.version}"

    patchPythonScript "$out/$installPrefix/pythonFiles/lib/python/isort/main.py"
  '';

  meta = with lib; {
    license = licenses.mit;
    platforms = [ "x86_64-linux" ];
    maintainers = [ maintainers.jraygauthier ];
  };
}
