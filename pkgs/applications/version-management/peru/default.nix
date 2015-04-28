{ stdenv, fetchurl, python3Packages }:

let 
  version = "0.1.3"; 
in

python3Packages.buildPythonPackage rec {
  
  # Do not prefix name with python specific version identifier.
  namePrefix = "";

  name = "peru-${version}";
  src = fetchurl {
    url = "https://github.com/buildinspace/peru/archive/${version}.tar.gz";
    sha256 = "01654iialzflwqzvy1n5452nakg2n8pn608nl47idmyih0hb8sh6";
  };

  pythonPath = with python3Packages; [ pyyaml docopt ];

  meta = {
    homepage = https://github.com/buildinspace/peru;
    description = "A tool for including other people's code in your projects";
    license = stdenv.lib.licenses.mit;
  };
}