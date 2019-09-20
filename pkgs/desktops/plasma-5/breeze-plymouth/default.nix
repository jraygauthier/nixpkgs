{
  mkDerivation,
  lib,
  copyPathsToStore,
  extra-cmake-modules,
  plymouth,
  nixos-icons,
  imagemagick,
  netpbm,
  perl,
  logoName ? "nixos",
  logoFile ? null,
  osName ? "NixOS",
  osVersion ? "",
  topColor ? "black",
  bottomColor ? "black"
}:

let 
  validColors = [ "black" "cardboard_grey" "charcoal_grey" "icon_blue" "paper_white" "plasma_blue" "neon_blue" "neon_green" ];
in
  assert lib.asserts.assertOneOf "topColor" topColor validColors;
  assert lib.asserts.assertOneOf "bottomColor" bottomColor validColors;
  
mkDerivation {
  name = "breeze-plymouth";
  nativeBuildInputs = [ extra-cmake-modules ];
  buildInputs = [ plymouth ] ++ lib.optionals (logoFile != null) [ imagemagick netpbm perl ];
  patches = copyPathsToStore (lib.readPathsFromFile ./. ./series);
  cmakeFlags = [
    "-DDISTRO_NAME=${osName}"
    "-DDISTRO_VERSION=${osVersion}"
    "-DDISTRO_LOGO=${logoName}"
    "-DBACKGROUND_TOP_COLOR=${topColor}"
    "-DBACKGROUND_BOTTOM_COLOR=${bottomColor}"
  ];
  
  postPatch = ''
      substituteInPlace cmake/FindPlymouth.cmake --subst-var out
  '' + lib.optionalString (logoFile != null) ''
      cp ${logoFile} breeze/images/${logoName}.logo.png

      # conversion for 16bit taken from the breeze-plymouth readme
      convert ${logoFile} -alpha Background -background "#000000" -fill "#000000" -flatten tmp.png
      pngtopnm tmp.png | pnmquant 16 | pnmtopng > ${logoName}.logo.png
  '';
}