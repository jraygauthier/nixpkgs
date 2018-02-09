{ stdenv, fetchurl
, pkgconfig
, python3Packages
, wrapGAppsHook
, atk
, dbus_libs
, evemu
, frame
, gdk_pixbuf
, gobjectIntrospection
, grail
, gtk3
, libX11
, libXext
, libXi
, libXtst
, pango
, xorgserver
}:

with stdenv.lib;

stdenv.mkDerivation rec {
  name = "geis-${version}";
  version = "2.2.17";

  src = fetchurl {
    url = "https://launchpad.net/geis/trunk/${version}/+download/${name}.tar.xz";
    sha256 = "1svhbjibm448ybq6gnjjzj0ak42srhihssafj0w402aj71lgaq4a";
  };

  NIX_CFLAGS_COMPILE = "-Wno-format -Wno-misleading-indentation -Wno-error";

  pythonWithPackages = python3Packages.python.withPackages (pp: with pp; [ 
    pygobject3  
  ]);

  nativeBuildInputs = [ pkgconfig wrapGAppsHook ];

  buildInputs = [ atk dbus_libs evemu frame gdk_pixbuf gobjectIntrospection grail
    gtk3 libX11 libXext libXi libXtst pango pythonWithPackages xorgserver
    python3Packages.wrapPython
  ];

  patchPhase = ''
    substituteInPlace python/geis/geis_v2.py --replace \
      "ctypes.util.find_library(\"geis\")" "'$out/lib/libgeis.so'"
  '';

  preFixup = ''
    gappsWrapperArgs+=(--set PYTHONPATH "$(toPythonPath $out)")
  '';

  meta = {
    description = "A library for input gesture recognition";
    homepage = https://launchpad.net/geis;
    license = licenses.gpl2;
    platforms = platforms.linux;
  };
}
