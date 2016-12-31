{ stdenv, fetchsvn, fetchpatch, cmake, zlib, expat, gettext }:

stdenv.mkDerivation rec {
  name = "exiv2-0.25";

  
/*
  src = fetchurl {
    url = "http://www.exiv2.org/${name}.tar.gz";
    sha256 = "197g6vgcpyf9p2cwn5p5hb1r714xsk1v4p96f5pv1z8mi9vzq2y8";
  };
*/

  #patch = [
  #  ./changeset_r3889.diff
  #  ./changeset_r3890.diff
  #];

  # Fix [Bug #1106: Crash in exiv2 due to assertion when setting rating on jpg with a Casio makernote - Exiv2
  # ](http://dev.exiv2.org/issues/1106).
  src = fetchsvn {
    url = "svn://dev.exiv2.org/svn/trunk";
    rev = "4499";
    sha256 = "0y8xkqrz058cnyvxnnkrp2ha8yzk4nmn0gb72ay9d7mywqxzgv4p";
  };

  postPatch = "patchShebangs ./src/svn_version.sh";

  buildInputs = [ cmake ];
  nativeBuildInputs = [ gettext ];
  propagatedBuildInputs = [ zlib expat ];

  meta = {
    homepage = http://www.exiv2.org/;
    description = "A library and command-line utility to manage image metadata";
    platforms = stdenv.lib.platforms.all;
  };
}
