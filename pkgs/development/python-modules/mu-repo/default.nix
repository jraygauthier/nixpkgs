{ stdenv, fetchPypi, buildPythonPackage, pyyaml_5
}:

buildPythonPackage rec {
  pname = "mu-repo";
  version = "1.8.0";
  name = pname + "-" + version;
  # pnamePyPi = "mu_repo";

  src = fetchPypi {
    pname = "mu_repo";
    inherit version;
    sha256 = "16hzzv0n5brvba8byz1kychwikcgidy7p2hcj6273xv07nrm7iw0";
  };

  propagatedBuildInputs = [ pyyaml_5 ];

  # Failing with "ImportError: cannot import name 'windll' from 'ctypes'".
  doCheck = false;

  meta = with stdenv.lib; {
    homepage = "http://fabioz.github.io/mu-repo";
    license = licenses.gpl3;
    description = "Tool to work with multiple git repositories";
    maintainers = with maintainers; [ jraygauthier ];
  };
}
