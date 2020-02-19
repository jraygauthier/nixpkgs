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

/*

  Fails with:

  ```
  # ..
  [ 35%] Generating Tcam-0.1.gir
  gcc -E -I. -I/build/source/src -I/nix/store/j7idmzqpn9xrqxm7mwblw3y3b465xli1-glib-2.60.7-dev/include -I/nix/store/j7idmzqpn9xrqxm7mwblw3y3b465xli1-glib-2.60.7-dev/include/glib-2.0 -I/nix/store/5wyxwd5a3bg31rdlxk1j62mm8bq96hd8-glib-2.60.7/lib/glib-2.0/include -o g-ir-cpp-uxdp_1e4.i -C /build/source/src/gobject/g-ir-cpp-uxdp_1e4.c
  gcc -I/build/source/src -I/nix/store/j7idmzqpn9xrqxm7mwblw3y3b465xli1-glib-2.60.7-dev/include -I/nix/store/j7idmzqpn9xrqxm7mwblw3y3b465xli1-glib-2.60.7-dev/include/glib-2.0 -I/nix/store/5wyxwd5a3bg31rdlxk1j62mm8bq96hd8-glib-2.60.7/lib/glib-2.0/include -I/nix/store/j7idmzqpn9xrqxm7mwblw3y3b465xli1-glib-2.60.7-dev/include -I/nix/store/j7idmzqpn9xrqxm7mwblw3y3b465xli1-glib-2.60.7-dev/include/glib-2.0 -I/nix/store/5wyxwd5a3bg31rdlxk1j62mm8bq96hd8-glib-2.60.7/lib/glib-2.0/include -c /build/source/src/gobject/tmp-introspectmh065mzq/Tcam-0.1.c -o /build/source/src/gobject/tmp-introspectmh065mzq/Tcam-0.1.o -Wall -Wno-deprecated-declarations -pthread
  g-ir-scanner: link: gcc -o /build/source/src/gobject/tmp-introspectmh065mzq/Tcam-0.1 /build/source/src/gobject/tmp-introspectmh065mzq/Tcam-0.1.o -L. -Wl,-rpath,. -Wl,--no-as-needed -L/build/source/build/src/gobject -Wl,-rpath,/build/source/build/src/gobject -ltcamprop -L/nix/store/5wyxwd5a3bg31rdlxk1j62mm8bq96hd8-glib-2.60.7/lib -lgio-2.0 -Wl,--export-dynamic -pthread -lgmodule-2.0 -lgobject-2.0 -lglib-2.0
  /nix/store/q354712mnkw3ky8b5crj7ir7dyv29ylj-binutils-2.31.1/bin/ld: warning: libtcam-dfk73.so.0, needed by /build/source/build/src/gobject/libtcamprop.so, not found (try using -rpath or -rpath-link)
  /nix/store/q354712mnkw3ky8b5crj7ir7dyv29ylj-binutils-2.31.1/bin/ld: /build/source/build/src/libtcam.so.0: undefined reference to `dfk73_v4l2_set_framerate_index'
  collect2: error: ld returned 1 exit status
  linking of temporary binary failed: Command '['gcc', '-o', '/build/source/src/gobject/tmp-introspectmh065mzq/Tcam-0.1', '/build/source/src/gobject/tmp-introspectmh065mzq/Tcam-0.1.o', '-L.', '-Wl,-rpath,.', '-Wl,--no-as-needed', '-L/build/source/build/src/gobject', '-Wl,-rpath,/build/source/build/src/gobject', '-ltcamprop', '-L/nix/store/5wyxwd5a3bg31rdlxk1j62mm8bq96hd8-glib-2.60.7/lib', '-lgio-2.0', '-Wl,--export-dynamic', '-pthread', '-lgmodule-2.0', '-lgobject-2.0', '-lglib-2.0']' returned non-zero exit status 1.
  make[2]: *** [src/gobject/CMakeFiles/create_gobject.dir/build.make:65: src/gobject/Tcam-0.1.gir] Error 1
  make[1]: *** [CMakeFiles/Makefile2:344: src/gobject/CMakeFiles/create_gobject.dir/all] Error 2
  make: *** [Makefile:152: all] Error 2
  builder for '/nix/store/v6xa0lbs6priicj3hab6fj9nm7naxhxc-tiscamera-unstable-20200128.drv' failed with exit code 2
  error: build of '/nix/store/g5mnmm1b3pm6kd185mvyhhchl7pb31vp-python3-interpreter-in-system-env.drv', '/nix/store/v6xa0lbs6priicj3hab6fj9nm7naxhxc-tiscamera-unstable-20200128.drv' failed
  ```
*/

stdenv.mkDerivation rec {
  pname = "tiscamera";
  version = "unstable-20200128";
  name = "${pname}-${version}";

  src = fetchFromGitHub {
    owner = "TheImagingSource";
    repo = pname;
    # Tracks the development
    rev = "543412ab3a143846553e3f14a1b1120680735f2d";
    sha256 = "03vxi1kc9k3hgmpiqpa89drlcaly7cp03yk85dc6a709accf29wx";
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