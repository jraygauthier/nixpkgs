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

        Does not seem the cause issues that I know of.
    
     2. > Error: /usr/local/Brother/Printer/MFC7860DW/inf/brMFC7860DWrc :cannot open file !!
        > ...
        > Error: /usr/local/Brother/Printer/MFC7860DW/inf/brMFC7860DWfunc :cannot open file !!
        
        When running the following from inside 
        `$out/usr/local/Brother/Printer/MFC7860DW/cupswrapper`

        ~~~
        ./brcupsconfig4  MFC7860DW  /etc/cups/ppd/MFC7860DW.ppd 2
        ~~~

        Now that we patch and compile `brcupsconfig4` ourselve another problem
        of the same nature (hardcoded paths) occurs for `brprintconflsr3` binary from the
        `mfc7860dwlpr` package. Unfortunatly no source code is provided by the manufacturer
        for this package, so this is not something we can fix. 
 
        Even tough I couldn't see any adverse effects resulting from this issue, here is
        a easy hack that can be added to your `configuration.nix` to fix the problem in
        an impure way:

        ~~~
        environment.usr."local/Brother/Printer/MFC7860DW/inf/brMFC7860DWfunc".source =
          "${pkgs.mfc7860dwlpr}/usr/local/Brother/Printer/MFC7860DW/inf/brMFC7860DWfunc";
        environment.usr."local/Brother/Printer/MFC7860DW/inf/brMFC7860DWrc".source =
          "${pkgs.mfc7860dwlpr}/usr/local/Brother/Printer/MFC7860DW/inf/brMFC7860DWrc";
        ~~~

        Note that an alternate way (which could be much better in term of modularity) would
        be to implement this driver as a nixos module instead or as well. 

*/

stdenv.mkDerivation {

  name = "brmfc7860dwcups-2.0.4-2";
  src = fetchurl {
    url = "http://download.brother.com/welcome/dlf006765/brmfc7860dwcups_src-2.0.4-2.tar.gz";
    sha256 = "0waw78pzafy3j3ljfmyqj3fpm3cnq55fvcq01iwgg79aam3x5x1a";
  };

  buildInputs = [ cups perl mfc7860dwlpr ];

  patchPhase = ''
    CUPSWRAPPER=usr/local/Brother/Printer/MFC7860DW/cupswrapper
    INFDIR=usr/local/Brother/Printer/MFC7860DW/inf
    LPDDIR=usr/local/Brother/Printer/MFC7860DW/lpd
    INSTALL_SCRIPT=cupswrapperMFC7860DW-2.0.4
    CONFIG_C=brcupsconfig3/brcupsconfig.c

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

    substituteInPlace $CONFIG_C \
      --replace "BASEDIR \"/usr" "BASEDIR \"${mfc7860dwlpr}/usr" \
      --replace "SETTINGFILE \"/usr" "SETTINGFILE \"$out/usr"
  '';

  buildPhase = ''
    # Oddly use `brcupsconfig4` in `brlpdwrapperMFC7860DW` and install script.
    gcc brcupsconfig3/brcupsconfig.c -obrcupsconfig4
  '';

  installPhase = ''
    CUPSFILTER=$out/lib/cups/filter
    CUPSPPD=$out/share/cups/model

    CUPSWRAPPER=usr/local/Brother/Printer/MFC7860DW/cupswrapper

    mkdir -p $out/$CUPSWRAPPER
    cp -p cupswrapperMFC7860DW-2.0.4 $out/$CUPSWRAPPER
    cp -p brcupsconfig4 $out/$CUPSWRAPPER

    # Make sure that following scripts use the proper directories for filters and ppds
    # by creating the right folders.
    mkdir -p $CUPSFILTER
    mkdir -p $CUPSPPD
    $out/$CUPSWRAPPER/cupswrapperMFC7860DW-2.0.4 -i
  '';

  meta = {
    description = "Brother MFC7860DW CUPS wrapper driver";
    homepage = http://www.brother.com;
    platforms = stdenv.lib.platforms.linux;
    license = stdenv.lib.licenses.gpl2Plus;
  };
}

