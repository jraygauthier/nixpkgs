{ lib
, stdenv
, fetchFromGitHub
, cmake
, pkgconfig
, bash
, glib
, gobject-introspection
, gst_all_1
, libunwind
, libusb1
, libuuid
, libzip
, orc
, pcre
, python3
, python3Packages
, tinyxml
, wrapGAppsHook
, wrapQtAppsHook
, qtbase
}:

stdenv.mkDerivation rec {
  pname = "tiscamera";
  version = "unstable-20190719";
  name = "${pname}-${version}";

  src = fetchFromGitHub {
    owner = "TheImagingSource";
    repo = pname;
    rev = "2042bba574c2b4280027b041881afae5a9e000d8";
    sha256 = "1kfh1bsakpm3j9z5p654p8bnwardm4274g6knb6fs57v20a4l9f4";
  };

  nativeBuildInputs = [
    cmake
    pkgconfig
    python3Packages.wrapPython
    wrapGAppsHook
    wrapQtAppsHook
  ];

  buildInputs = [
    bash
    glib
    gobject-introspection
    gst_all_1.gst-plugins-base
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    libunwind
    libusb1
    libuuid
    libzip
    orc
    pcre
    tinyxml
    python3Packages.python
    python3Packages.pyqt5
  ];

  pythonPath = with python3Packages; [ pyqt5 pygobject3 ];

  propagatedBuildInputs = pythonPath;

  cmakeFlags = [
    "-DBUILD_ARAVIS=OFF" # For GigE support. Won't need it as our camera is usb.
    "-DBUILD_GST_1_0=ON"
    "-DBUILD_TOOLS=ON"
    "-DBUILD_V4L2=ON"
    "-DBUILD_LIBUSB=ON"
  ];

  patches = [
    ./0001-Device-lost-hang-official-patch.patch
  ];

  postPatch = ''
    substituteInPlace ./data/udev/80-theimagingsource-cameras.rules.in \
      --replace "/bin/sh" "${bash}/bin/sh" \
      --replace "typically /usr/bin/" "" \
      --replace "typically /usr/share/theimagingsource/tiscamera/uvc-extension/" ""

    substituteInPlace ./src/BackendLoader.cpp \
      --replace '"libtcam-v4l2.so"' "\"$out/lib/tcam-0/libtcam-v4l2.so\"" \
      --replace '"libtcam-aravis.so"' "\"$out/lib/tcam-0/libtcam-aravis.so\"" \
      --replace '"libtcam-libusb.so"' "\"$out/lib/tcam-0/libtcam-libusb.so\""
  '';

  preConfigure = ''
    cmakeFlagsArray=(
      $cmakeFlagsArray
      "-DCMAKE_INSTALL_PREFIX=$out"
      "-DTCAM_INSTALL_UDEV=$out/lib/udev/rules.d"
      "-DTCAM_INSTALL_UVCDYNCTRL=$out/share/uvcdynctrl/data/199e"
      "-DTCAM_INSTALL_GST_1_0=$out/lib/gstreamer-1.0"
      "-DTCAM_INSTALL_GIR=$out/share/gir-1.0"
      "-DTCAM_INSTALL_TYPELIB=$out/lib/girepository-1.0"
      "-DTCAM_INSTALL_SYSTEMD=$out/etc/systemd/system"
      "-DTCAM_INSTALL_PYTHON3_MODULES=$out/lib/${python3.libPrefix}/site-packages"
    )
  '';


  # There are gobject introspection commands launched as part of the build. Those have a runtime
  # dependency on `libtcam` (which itself is built as part of this build). In order to allow
  # that, we set the dynamic linker's path to point on the build time location of the library.
  preBuild = ''
    export LD_LIBRARY_PATH=$PWD/src:$LD_LIBRARY_PATH
  '';

  preInstall = ''
    mkdir -p "$out/lib/${python3.libPrefix}/site-packages"
  '';

  postInstall = ''
    install -m 0755 "./tools/firmware-update/firmware-update" "$out/bin/tiscamera-firmware-update"
  '';

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
    homepage = https://github.com/TheImagingSource/tiscamera;
    license = with licenses; [ asl20 ];
    platforms = platforms.linux;
    maintainers = with maintainers; [ jraygauthier ];
  };
}
