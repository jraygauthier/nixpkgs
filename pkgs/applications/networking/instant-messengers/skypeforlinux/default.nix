{ stdenv, fetchurl, dpkg, makeWrapper
, alsaLib, atk, cairo, cups, curl, dbus, expat, fontconfig, freetype, glib, gnome2
, libnotify, libpulseaudio, libsecret, libv4l, nspr, nss, systemd, xorg }:

let

  version = "8.10.76.7";

  rpath = stdenv.lib.makeLibraryPath [
    alsaLib
    atk
    cairo
    cups
    curl
    dbus
    expat
    fontconfig
    freetype
    glib

    gnome2.GConf
    gnome2.gdk_pixbuf
    gnome2.gtk
    gnome2.pango

    gnome2.gnome_keyring

    libnotify
    libpulseaudio
    libv4l.out
    nspr
    nss
    stdenv.cc.cc
    systemd

    xorg.libxkbfile
    xorg.libX11
    xorg.libXcomposite
    xorg.libXcursor
    xorg.libXdamage
    xorg.libXext
    xorg.libXfixes
    xorg.libXi
    xorg.libXrandr
    xorg.libXrender
    xorg.libXtst
    xorg.libXScrnSaver
    xorg.libxcb
  ] + ":${stdenv.cc.cc.lib}/lib64";

  src =
    if stdenv.system == "x86_64-linux" then
      fetchurl {
        url = "https://repo.skype.com/deb/pool/main/s/skypeforlinux/skypeforlinux_${version}_amd64.deb";
        sha256 = "1nh0rcglslgl3wwlbkrak3p9db9jrjw89br6fi4g4mcb81bcjb0q";
      }
    else
      throw "Skype for linux is not supported on ${stdenv.system}";

in stdenv.mkDerivation {
  name = "skypeforlinux-${version}";

  system = "x86_64-linux";

  inherit src;

  buildInputs = [ dpkg makeWrapper ];

  unpackPhase = "true";
  installPhase = ''
    mkdir -p $out
    dpkg -x $src $out
    cp -av $out/usr/* $out
    rm -rf $out/opt $out/usr
    rm $out/bin/skypeforlinux

    # Otherwise it looks "suspicious"
    chmod -R g-w $out
  '';

  postFixup = ''
     patchelf \
      --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
      --set-rpath "$out/share/skypeforlinux:${rpath}" "$out/share/skypeforlinux/skypeforlinux"

    #
    # Fix the dynamic load of 'libsecret'.
    # Fix the `STARTUP_LOAD_ERROR` after login by preloading the v4l1 compatibility lib.
    #
    makeWrapper "$out/share/skypeforlinux/skypeforlinux" "$out/bin/skypeforlinux" \
      --prefix LD_LIBRARY_PATH : "${libsecret.out}/lib" \
      --prefix LD_PRELOAD : "${libv4l.out}/lib/v4l1compat.so"

    # Fix the desktop link
    substituteInPlace $out/share/applications/skypeforlinux.desktop \
      --replace /usr/bin/ $out/bin/ \
      --replace /usr/share/ $out/share/
  '';

  meta = with stdenv.lib; {
    description = "Linux client for skype";
    homepage = https://www.skype.com;
    license = licenses.unfree;
    maintainers = with stdenv.lib.maintainers; [ panaeon jraygauthier ];
    platforms = [ "x86_64-linux" ];
  };
}

