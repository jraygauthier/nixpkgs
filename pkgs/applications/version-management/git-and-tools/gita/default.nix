{ lib, python3Packages }:

python3Packages.buildPythonApplication rec {
  version = "0.7.3";
  pname = "gita";

  src = python3Packages.fetchPypi {
    inherit pname version;
    sha256 = "0ccqjf288513im7cvafiw4ypbp9s3z0avyzd4jzr13m38jrsss3r";
  };

  bashCompletionScript = builtins.fetchurl {
    name = "gita-bash-completion";
    url = https://raw.githubusercontent.com/nosarthur/gita/a37d676d90ba85364dbe80307070338360f09041/.gita-completion.bash;
    sha256 = "0zzqsjrdg6dakyzfz3jjdhcck5nw6yx1ab75ggxbf38ypbxrf9al";
  };

  propagatedBuildInputs = with python3Packages; [
    pyyaml
  ];

  doCheck = false;  # Releases don't include tests

  postInstall = ''
    install -D "${bashCompletionScript}" "$out/share/bash-completion/completions/gita"
  '';

  meta = with lib; {
    description = "A command-line tool to manage multiple git repos";
    homepage = https://github.com/nosarthur/gita;
    license = licenses.mit;
    maintainers = with maintainers; [ seqizz ];
  };
}
