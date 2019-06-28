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
, tinyxml
}:

stdenv.mkDerivation rec {
  pname = "tiscamera";
  version = "unstable-20190627";
  name = "${pname}-${version}";

  src = fetchFromGitHub {
    owner = "TheImagingSource";
    repo = pname;
    rev = "b454a8bb06dbcb9e3d3434a03a72d3d2fa44c11e";
    sha256 = "1b21z0w6b9cb58xbk0sqahznb7flhshbn227j1kmhckb9vw7g2jn";
  };

  nativeBuildInputs = [
    cmake
    pkgconfig
  ];

  buildInputs = [
    bash
    glib
    gobject-introspection
    gst_all_1.gst-plugins-base
    gst_all_1.gstreamer
    libunwind
    libusb1
    libuuid
    libzip
    orc
    pcre
    python3
    tinyxml
  ];


  cmakeFlags = [
    "-DBUILD_ARAVIS=OFF" # For GigE support. Won't need it as our camera is usb.
    "-DBUILD_GST_1_0=ON"
    "-DBUILD_TOOLS=ON"
    "-DBUILD_V4L2=ON"
    "-DBUILD_LIBUSB=ON"
  ];


  patches = [
    # ./p-0003-comment-out-a-line-that-segfaults-the-app.patch
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

  meta = with lib; {
    description = "The Linux sources and UVC firmwares for The Imaging Source cameras";
    homepage = https://github.com/TheImagingSource/tiscamera;
    license = with licenses; [ asl20 ];
    platforms = platforms.linux;
    maintainers = with maintainers; [ jraygauthier ];
  };
}