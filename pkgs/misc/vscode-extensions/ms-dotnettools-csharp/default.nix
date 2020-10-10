{ lib
, fetchurl
, vscode-utils
, unzip
, patchelf
, makeWrapper
, icu
, stdenv
, openssl
, mono6
}:

let
  # Get as close as possible as the `package.json` required version.
  # This is what drives omnisharp.
  mono = mono6;

  rtDepsSrcsFromJson = builtins.fromJSON (builtins.readFile ./rt-deps-bin-srcs.json);

  rtDepsBinSrcs = builtins.mapAttrs (k: v:
      let
        # E.g: "OmniSharp-x86_64-linux"
        kSplit = builtins.split "(-)" k;
        name = builtins.elemAt kSplit 0;
        arch = builtins.elemAt kSplit 2;
        platform = builtins.elemAt kSplit 4;
      in
      {
        inherit name arch platform;
        installPath = v.installPath;
        binaries = v.binaries;
        bin-src = fetchurl {
          urls = v.urls;
          sha256 = v.sha256;
        };
      }
    )
    rtDepsSrcsFromJson;

  arch = "x86_64";
  platform = "linux";

  rtDepBinSrcByName = bSrcName:
    rtDepsBinSrcs."${bSrcName}-${arch}-${platform}";

  omnisharp = rtDepBinSrcByName "OmniSharp";
  vsdbg = rtDepBinSrcByName "Debugger";
  razor = rtDepBinSrcByName "Razor";
in

vscode-utils.buildVscodeMarketplaceExtension {
  mktplcRef = {
    name = "csharp";
    publisher = "ms-dotnettools";
    version = "1.23.2";
    sha256 = "0ydaiy8jfd1bj50bqiaz5wbl7r6qwmbz9b29bydimq0rdjgapaar";
  };

  nativeBuildInputs = [
    unzip
    patchelf
    makeWrapper
  ];

  postPatch = ''
    unzip_to() {
      declare src_zip="''${1?}"
      declare target_dir="''${2?}"
      mkdir -p "$target_dir"
      if unzip "$src_zip" -d "$target_dir"; then
        true
      elif [[ "1" -eq "$?" ]]; then
        1>&2 echo "WARNING: unzip('$?' -> skipped files)."
      else
        1>&2 echo "ERROR: unzip('$?')."
      fi
    }

    patchelf_add_icu_as_needed() {
      declare elf="''${1?}"
      declare icu_major_v="${
        with builtins; head (splitVersion (parseDrvName icu.name).version)}"

      for icu_lib in icui18n icuuc icudata; do
        patchelf --add-needed "lib''${icu_lib}.so.$icu_major_v" "$elf"
      done
    }

    patchelf_common() {
      declare elf="''${1?}"

      patchelf_add_icu_as_needed "$elf"
      patchelf --add-needed "libssl.so" "$elf"
      patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
        --set-rpath "${lib.makeLibraryPath [ stdenv.cc.cc openssl.out icu.out ]}:\$ORIGIN" \
        "$elf"
    }

    declare omnisharp_dir="$PWD/${omnisharp.installPath}"
    unzip_to "${omnisharp.bin-src}" "$omnisharp_dir"
    rm "$omnisharp_dir/bin/mono"
    ln -s -T "${mono6}/bin/mono" "$omnisharp_dir/bin/mono"
    chmod a+x "$omnisharp_dir/run"
    touch "$omnisharp_dir/install.Lock"

    declare vsdbg_dir="$PWD/${vsdbg.installPath}"
    unzip_to "${vsdbg.bin-src}" "$vsdbg_dir"
    chmod a+x "$vsdbg_dir/vsdbg-ui"
    chmod a+x "$vsdbg_dir/vsdbg"
    touch "$vsdbg_dir/install.complete"
    touch "$vsdbg_dir/install.Lock"
    patchelf_common "$vsdbg_dir/vsdbg"
    patchelf_common "$vsdbg_dir/vsdbg-ui"

    declare razor_dir="$PWD/${razor.installPath}"
    unzip_to "${razor.bin-src}" "$razor_dir"
    chmod a+x "$razor_dir/rzls"
    touch "$razor_dir/install.Lock"
    patchelf_common "$razor_dir/rzls"
  '';

  meta = with lib; {
    license = licenses.mit;
    maintainers = [ maintainers.jraygauthier ];
    platforms = [ "x86_64-linux" ];
  };
}
