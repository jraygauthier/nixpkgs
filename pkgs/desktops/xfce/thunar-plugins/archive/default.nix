{ stdenv, fetchFromGitHub, pkgconfig, xfce4_dev_tools
, gtk
, thunar
, exo, libxfce4util, libxfce4ui
, xfconf, udev, libnotify
}:

stdenv.mkDerivation rec {
  p_name  = "thunar-archive-plugin";
  ver_maj = "0.3";
  ver_min = "1";
  name = "${p_name}-${ver_maj}.${ver_min}";

  src = fetchFromGitHub {
    owner = "xfce-mirror";
    repo = "thunar-archive-plugin";
    rev = "72b23eefc348bee31e06a04f968e430bc7dfa51e";
    sha256 = "0l8715x23qmk0jkywiza3qx0xxmafxi4grp7p82kkc5df5ccs8kx";
  };

  buildInputs = [
    pkgconfig
    xfce4_dev_tools
    thunar
    exo gtk libxfce4util libxfce4ui
    xfconf udev libnotify
  ];

  preConfigure = ''
    ./autogen.sh
  '';

  /*
    File roller `*.desktop` situation
    ---------------------------------

    For some odd reason, in nix os, gnome file-roller's desktop file has the non-standard name
    `org.gnome.FileRoller.desktop`. In order to be compatible with this odd context, create
    a `*.tap` file of the same name.

    IMPORTANT: Adapt or remove the symbolic link if the situation changes.
  */
  preFixup = ''
    pushd $out/libexec/thunar-archive-plugin > /dev/null
    ln -s ./file-roller.tap org.gnome.FileRoller.tap
    popd > /dev/null
    rm $out/share/icons/hicolor/icon-theme.cache
  '';

  enableParallelBuilding = true;

  meta = {
    homepage = http://foo-projects.org/~benny/projects/thunar-archive-plugin/;
    description = "The Thunar Archive Plugin allows you to create and extract archive files using the file context menus in the Thunar file manager";
    license = stdenv.lib.licenses.gpl2Plus;
    platforms = stdenv.lib.platforms.linux;
  };
}
