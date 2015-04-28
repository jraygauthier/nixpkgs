{ stdenv, fetchurl, cups, perl, mfc7860dwlpr, debugLvl ? "0"}:

/*
    [Setup instructions](http://support.brother.com/g/s/id/linux/en/instruction_prn1a.html).

    URI example
     ~  `lpd://BRW0080927AFBCE/binary_p1`

    Logging
    -------
    
    `/tmp/br_cupsfilter_debug_log` when `DEBUG > 0` in `brlpdwrapperMFC7860DW`.
    Note that when `DEBUG > 1` the wrapper stops performing its function. Better
    keep `DEBUG == 1` unless this is desirable.

    Now activable through this package's `debugLvl` parameter whose value is to be
    used to establish `DEBUG`.


    Issues
    ------
  
     1. Uses `/usr/bin/psnup`. This is part of the `psutils` package which does
        not seems available on nix. See
        
        <http://www.ctan.org/tex-archive/support/psutils>

        <https://packages.debian.org/sid/psutils>
    
     2. > sh: /usr/local/Brother/Printer/MFC7860DW/inf/brprintconflsr3: No such file or directory

        Occurs before the filter. It seem in fact to be `brcupsconfig3` which has some internally
        hard coded paths.

        ~~~
        ./brcupsconfig4  MFC7860DW  /etc/cups/ppd/MFC7860DW.ppd 2
        ~~~

        Fortunately, Brothers provide this executable in the source code form in the package
        `brmfc7860dwcups_src-2.0.4-2`. All that remains to do is to add this package to nix
        and modify the current package so that it used the compiled program instead of
        one it was shipped with.

        See `brmfc7860dwcups` nix package which partially fix this issue.

        Even tough I couldn't see any adverse effects resulting from this issue, here is
        a easy hack that can be added to your `configuration.nix` to fix the problem in
        an impure way:

        ~~~
        environment.usr."local/Brother/Printer/MFC7860DW/inf/brprintconflsr3".source =
          "${pkgs.mfc7860dwlpr}/usr/local/Brother/Printer/MFC7860DW/inf/brprintconflsr3";
        environment.usr."local/Brother/Printer/MFC7860DW/inf/brMFC7860DWfunc".source =
          "${pkgs.mfc7860dwlpr}/usr/local/Brother/Printer/MFC7860DW/inf/brMFC7860DWfunc";
        environment.usr."local/Brother/Printer/MFC7860DW/inf/brMFC7860DWrc".source =
          "${pkgs.mfc7860dwlpr}/usr/local/Brother/Printer/MFC7860DW/inf/brMFC7860DWrc";
        ~~~

        Note that an alternate way (which could be much better in term of modularity) would
        be to implement this driver as a nixos module instead or as well. 
*/

let myPatchElf = (file: 
  if stdenv.system == "i686-linux" then ''
    patchelf --set-interpreter ${stdenv.glibc}/lib/ld-linux.so.2 ${file}
  '' else if stdenv.system == "x86_64-linux" then ''
    patchelf --set-interpreter ${stdenv.glibc}/lib/ld-linux-x86-64.so.2 ${file}
  '' else "");
in 
stdenv.mkDerivation {

  name = "cupswrapperMFC7860DW-2.0.4-2";
  src = fetchurl {
    url = "http://download.brother.com/welcome/dlf006287/cupswrapperMFC7860DW-2.0.4-2.i386.deb";
    sha256 = "1pnsg58zb6ny4p1kl7w8bj2w87z8xqwpvvcbl414jcs5465k2a9z";
  };

  unpackPhase = ''
    ar x $src
    tar xfvz data.tar.gz
  '';

  buildInputs = [ cups perl mfc7860dwlpr ];
  buildPhase = ''
    true
  '';

 patchPhase = ''
    CUPSWRAPPER=usr/local/Brother/Printer/MFC7860DW/cupswrapper
    INFDIR=usr/local/Brother/Printer/MFC7860DW/inf
    LPDDIR=usr/local/Brother/Printer/MFC7860DW/lpd
    INSTALL_SCRIPT=$CUPSWRAPPER/cupswrapperMFC7860DW-2.0.4

    # cupsd expect its stuff under `share` and `lib` instead of `user/share` and `user/lib`.
    # Nothing after `chmod 755 \$brotherlpdwrapper` should be executed.
    substituteInPlace $INSTALL_SCRIPT \
      --replace /usr/share "$out/share" \
      --replace /usr/lib "$out/lib" \
      --replace /usr/lib64 "$out/lib64" \
      --replace /usr/bin "$out/usr/bin" \
      --replace /etc "$out/etc" \
      --replace "\\\$PRINTER" "MFC7860DW" \
      --replace "/$LPDDIR" "${mfc7860dwlpr}/$LPDDIR" \
      --replace "/$INFDIR" "${mfc7860dwlpr}/$INFDIR" \
      --replace "/$CUPSWRAPPER" "$out/$CUPSWRAPPER" \
      --replace "DEBUG=0" "DEBUG=${debugLvl}" \
      --replace "chmod 755 \$brotherlpdwrapper" "chmod 755 \$brotherlpdwrapper; exit 0"

    ${myPatchElf "$CUPSWRAPPER/brcupsconfig4"}
  '';

  installPhase = ''
    CUPSFILTER=$out/lib/cups/filter
    CUPSPPD=$out/share/cups/model

    CUPSWRAPPER=usr/local/Brother/Printer/MFC7860DW/cupswrapper

    mkdir -p $out/$CUPSWRAPPER
    cp -rp $CUPSWRAPPER/* $out/$CUPSWRAPPER

    # Make sure that following scripts use the proper directories for filters and ppds
    # by creating the right folders.
    mkdir -p $CUPSFILTER
    mkdir -p $CUPSPPD
    $out/$CUPSWRAPPER/cupswrapperMFC7860DW-2.0.4 -i
  '';

  dontPatchELF = true;

  meta = {
    description = "Brother MFC7860DW CUPS wrapper driver";
    homepage = http://www.brother.com;
    platforms = stdenv.lib.platforms.linux;
    license = stdenv.lib.licenses.gpl2Plus;
  };
}

