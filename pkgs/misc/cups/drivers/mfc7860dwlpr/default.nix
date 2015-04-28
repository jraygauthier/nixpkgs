{ stdenv, fetchurl, cups, perl, glibc, patchelf, ghostscript, which, file, makeWrapper}:

/*
    [Setup instructions](http://support.brother.com/g/s/id/linux/en/instruction_prn1a.html).

    URI example
     ~  `lpd://BRW0080927AFBCE/binary_p1`

    Issues
    ------

     1. Uses gs, pdf2ps, a2ps and /usr/bin/pstops.

        Fixed but for below which seems optional.

        TODO: a2ps. This one is not part of nix packages. The package could be found at
        <https://www.gnu.org/software/a2ps/> with tarball at 
        <http://ftp.gnu.org/gnu/a2ps/a2ps-4.10.4.tar.gz>.

     2. A misterious optional `$BR_PRT_PATH/inf/brPRINTERinit` in `filterMFC7860DW`.

        Seem optional indeed.

     3. Uses the `which` used by `psconvert2` and `file` by `filterMFC7860DW`.

        Fixed.

*/

let myPatchElf = (file: 
  if stdenv.system == "i686-linux" then ''
    patchelf --set-interpreter ${stdenv.glibc}/lib/ld-linux.so.2 ${file}
  '' else if stdenv.system == "x86_64-linux" then ''
    patchelf --set-interpreter ${stdenv.glibc}/lib/ld-linux-x86-64.so.2 ${file}
  '' else "");
in 
stdenv.mkDerivation {

  name = "mfc7860dwlpr-2.1.0-1";
  src = fetchurl {
    url = "http://download.brother.com/welcome/dlf006285/mfc7860dwlpr-2.1.0-1.i386.deb";
    sha256 = "1m9qkd76lxik869c6xgsrlbih5bkhi7dx980w4nwqclca2rbm7l9";
  };

  unpackPhase = ''
    ar x $src
    tar xfvz data.tar.gz
  '';

  buildInputs = [ cups perl glibc ghostscript which makeWrapper file];
  buildPhase = ''
    true
  '';

 patchPhase = ''
    INFDIR=usr/local/Brother/Printer/MFC7860DW/inf
    LPDDIR=usr/local/Brother/Printer/MFC7860DW/lpd

    # Fix part of issue #1 (pstops).
    substituteInPlace $LPDDIR/filterMFC7860DW \
      --replace "/usr/local" "$out/usr/local" \
      --replace "/usr/bin/pstops" "${cups}/lib/cups/filter/pstops"

    # Fix part of issue #1 (pstops).
    substituteInPlace $LPDDIR/psconvert2 \
      --replace "/usr/sbin/pstops" "${cups}/lib/cups/filter/pstops"

    ${myPatchElf "$INFDIR/braddprinter"}
    ${myPatchElf "$INFDIR/brprintconflsr3"}
    ${myPatchElf "$LPDDIR/rawtobr3"}
  '';

  installPhase = ''
    INFDIR=usr/local/Brother/Printer/MFC7860DW/inf
    LPDDIR=usr/local/Brother/Printer/MFC7860DW/lpd

    mkdir -p $out/$INFDIR
    cp -rp $INFDIR/* $out/$INFDIR
    mkdir -p $out/$LPDDIR
    cp -rp $LPDDIR/* $out/$LPDDIR

    # Fix part of issue #1 (pdf2ps) and issue #3 (file).
    wrapProgram $out/$LPDDIR/filterMFC7860DW \
      --prefix PATH ":" "${ghostscript}/bin" \
      --prefix PATH ":" "${file}/bin"

    # Fix part of issue #1 (gs) and issue #3 (which).
    wrapProgram $out/$LPDDIR/psconvert2 \
      --prefix PATH ":" "${ghostscript}/bin" \
      --prefix PATH ":" "${which}/bin"
  '';

  dontPatchELF = true;

  meta = {
    description = "Brother LPR driver";
    homepage = http://www.brother.com;
    platforms = stdenv.lib.platforms.linux;
    license = stdenv.lib.licenses.gpl2Plus;
  };
}