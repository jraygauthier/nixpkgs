{ stdenv, fetchPypi, buildPythonPackage, pyyaml_5
}:

buildPythonPackage rec {
  pname = "gita";
  version = "0.10.3";
  name = pname + "-" + version;

  src = fetchPypi {
    inherit pname version;
    sha256 = "0j0b788dw0c0wyn8wwgx2iiw024vm10fxqyrxhnshs3gnsba51rp";
  };

  bashCompletionScript = builtins.fetchurl {
    name = "gita-bash-completion";
    url = https://raw.githubusercontent.com/nosarthur/gita/a37d676d90ba85364dbe80307070338360f09041/.gita-completion.bash;
    sha256 = "0zzqsjrdg6dakyzfz3jjdhcck5nw6yx1ab75ggxbf38ypbxrf9al";
  };

  propagatedBuildInputs = [ pyyaml_5 ];

  doCheck = true;

  postInstall = ''
    install -D "${bashCompletionScript}" "$out/share/bash-completion/completions/gita"
  '';

  meta = with stdenv.lib; {
    description = "Manage multiple git repos";
    homepage = "https://github.com/nosarthur/gita";
    license = licenses.mit;
    maintainers = with maintainers; [ jraygauthier ];
  };
}
