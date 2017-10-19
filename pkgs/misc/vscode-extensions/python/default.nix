{ stdenv, lib, vscode-utils

, pythonUseFixed ? false, python  # When `true`, the python default setting will be fixed to specified. 
                                  # Use version from `PATH` for default default otherwise.
                                  # Defaults to `false` as we expect it to be project specific most of the time.
, ctagsUseFixed ? true, ctags     # When `true`, the ctags default setting will be fixed to specified. 
                                  # Use version from `PATH` for default setting otherwise.
                                  # Defaults to `true` as usually not defined on a per projet basis.
}:

assert pythonUseFixed -> null != python;
assert ctagsUseFixed -> null != ctags;

let
  pythonDefaultsTo = if pythonUseFixed then "${python}/bin/python" else "python";
  ctagsDefaultsTo = if ctagsUseFixed then "${ctags}/bin/ctags" else "ctags";
in

vscode-utils.buildVscodeMarketplaceExtension {
  mktplcRef = {
    name = "python";
    publisher = "donjayamanne";
    version = "0.7.0";
    sha256 = "1wc78cds1rzc7j3cp0kbr1qlfv38ik2rg5plq73q0nwkban8gikm";
  };

  postPatch = ''
    # Patch `packages.json` so that nix's *python* is used as default value for `python.pythonPath`.
    substituteInPlace "./package.json" \
      --replace "\"default\": \"python\"" "\"default\": \"${pythonDefaultsTo}\""

    # Patch `packages.json` so that nix's *ctags* is used as default value for `python.workspaceSymbols.ctagsPath`.
    substituteInPlace "./package.json" \
      --replace "\"default\": \"ctags\"" "\"default\": \"${ctagsDefaultsTo}\""
  '';

    meta = with lib; {
      license = licenses.mit;
      maintainer = [ maintainers.jraygauthier ];
    };
}