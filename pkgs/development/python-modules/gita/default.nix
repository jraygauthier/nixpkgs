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

  propagatedBuildInputs = [ pyyaml_5 ];

  doCheck = true;

  meta = with stdenv.lib; {
    description = "Manage multiple git repos";
    homepage = "https://github.com/nosarthur/gita";
    license = licenses.mit;
    maintainers = with maintainers; [ jraygauthier ];
  };
}
