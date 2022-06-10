{ lib
, stdenv
, fetchFromGitHub
, cmake
, meson
, pkg-config
, bash
, pcre
, tinyxml
, libusb1
, libzip
, glib
, gobject-introspection
, gst_all_1
, libwebcam
, libunwind
, elfutils
, orc
, python3Packages
, libuuid
, catch2
, wrapGAppsHook
, wrapQtAppsHook
, qtbase
, zstd
, graphviz
}:

stdenv.mkDerivation rec {
  pname = "tiscamera";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "TheImagingSource";
    repo = pname;
    rev = "v-${pname}-${version}";
    sha256 = "0msz33wvqrji11kszdswcvljqnjflmjpk0aqzmsv6i855y8xn6cd";
  };

  patches = [
    ./0001-tcamconvert-tcamsrc-add-missing-include-lib-dirs.patch
    ./0001-udev-rules-fix-install-location.patch
  ];

  postPatch = ''
    cp ${catch2}/include/catch2/catch.hpp external/catch/catch.hpp

    substituteInPlace ./data/udev/80-theimagingsource-cameras.rules.in \
      --replace "/bin/sh" "${bash}/bin/sh" \
      --replace "typically /usr/bin/" "" \
      --replace "typically /usr/share/theimagingsource/tiscamera/uvc-extension/" ""
  '';

  nativeBuildInputs = [
    cmake
    meson
    pkg-config
    python3Packages.wrapPython
    wrapGAppsHook
    wrapQtAppsHook
    python3Packages.sphinx
    graphviz
  ];

  buildInputs = [
    pcre
    tinyxml
    libusb1
    libzip
    glib
    gobject-introspection
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-ugly
    libwebcam
    libunwind
    elfutils
    orc
    libuuid
    python3Packages.python
    qtbase
    python3Packages.pyqt5
    zstd
  ];

  hardeningDisable = [ "format" ];

  pythonPath = with python3Packages; [ pyqt5 pygobject3 ];

  propagatedBuildInputs = pythonPath;

  cmakeFlags = [
    "-DTCAM_BUILD_WITH_GUI=ON"
    "-DTCAM_BUILD_ARAVIS=OFF" # For GigE support. Won't need it as our camera is usb.
    "-DTCAM_BUILD_GST_1_0=ON"
    "-DTCAM_BUILD_TOOLS=ON"
    "-DTCAM_BUILD_V4L2=ON"
    "-DTCAM_BUILD_LIBUSB=ON"
    "-DTCAM_BUILD_TESTS=ON"
    "-DTCAM_DOWNLOAD_MESON=OFF"
    "-DTCAM_INTERNAL_ARAVIS=OFF"
    "-DTCAM_ARAVIS_USB_VISION=OFF"
    "-DTCAM_INSTALL_FORCE_PREFIX=ON"
    # There are gobject introspection commands launched as part of the build. Those have a runtime
    # dependency on `libtcam` (which itself is built as part of this build). In order to allow
    # that, we set the dynamic linker's path to point on the build time location of the library.
    "-DCMAKE_SKIP_BUILD_RPATH=OFF"
  ];

  doCheck = true;

  # gstreamer tests requires, besides gst-plugins-bad, plugins installed by this expression.
  checkPhase = "ctest --force-new-ctest-process -E gstreamer";

  # wrapGAppsHook: make sure we add ourselves to the introspection
  # and gstreamer paths.
  GI_TYPELIB_PATH = "${placeholder "out"}/lib/girepository-1.0";
  GST_PLUGIN_SYSTEM_PATH_1_0 = "${placeholder "out"}/lib/gstreamer-1.0";

  QT_PLUGIN_PATH = "${qtbase.bin}/${qtbase.qtPluginPrefix}";

  preFixup = ''
    qtWrapperArgs+=("''${gappsWrapperArgs[@]}")
  '';

  postFixup = ''
    wrapPythonPrograms "$out $pythonPath"
  '';

  meta = with lib; {
    description = "The Linux sources and UVC firmwares for The Imaging Source cameras";
    homepage = "https://github.com/TheImagingSource/tiscamera";
    license = with licenses; [ asl20 ];
    platforms = platforms.linux;
    maintainers = with maintainers; [ jraygauthier ];
  };
}
