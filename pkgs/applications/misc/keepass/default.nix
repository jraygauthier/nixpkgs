{ stdenv, fetchurl, unzip, icoutils, makeDesktopItem, mono }:

stdenv.mkDerivation rec {
  name = "keepass-${version}";
  version = "2.29";

  src = fetchurl {
    url = "mirror://sourceforge/keepass/KeePass-${version}.zip";
    sha256 = "16x7m899akpi036c0wlr41w7fz9q0b69yac9q97rqkixb03l4g9d";
  };

  sourceRoot = ".";

  phases = [ "unpackPhase" "installPhase" ];

  desktopItem = makeDesktopItem {
    name = "keepass";
    exec = "keepass";
    comment = "Password manager";
    icon = "keepass";
    desktopName = "Keepass";
    genericName = "Password manager";
    type = "Application";
    categories = "Application;Utility;";
    mimeType = stdenv.lib.concatStringsSep ";" [
      "application/x-keepass2"
      ""
    ];
  };


  installPhase =
  let
    extractFDeskIcons=./extractWinRscIconsToStdFreeDesktopDir.sh;
  in
  ''
    mkdir -p "$out/bin"
    echo "${mono}/bin/mono $out/share/keepass/KeePass.exe" > $out/bin/keepass
    chmod +x $out/bin/keepass
    echo $out
    mkdir -p $out/share/keepass
    cp -r ./* $out/share/keepass
    mkdir -p "$out/share/applications"
    cp ${desktopItem}/share/applications/* $out/share/applications

    ${extractFDeskIcons} \
    "./KeePass.exe" \
    '[^\.]+\.exe_[0-9]+_[0-9]+_[0-9]+_[0-9]+_([0-9]+x[0-9]+)x[0-9]+\.png' \
    '\1' \
    '([^\.]+)\.exe.+' \
    'keepass' \
    "$out" \
    "./tmp"
  '';

  buildInputs = [ unzip icoutils ];

  meta = {
    description = "GUI password manager with strong cryptography";
    homepage = http://www.keepass.info/;
    maintainers = with stdenv.lib.maintainers; [amorsillo];
    platforms = with stdenv.lib.platforms; all;
    license = stdenv.lib.licenses.gpl2;
  };
}
