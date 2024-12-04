# vunit_hdl.nix
{ lib
, buildPythonPackage
, fetchPypi
, setuptools
, wheel
, setuptools_scm
, python3Packages
, colorama
}:

buildPythonPackage rec {
  pname = "vunit_hdl";  # Correct package name
  version = "4.7.0";

  src = fetchPypi {
    pname = "vunit_hdl";  # PyPI name uses hyphen
    inherit version;
    sha256 = "sha256-ol+5kbq9LqhRlm4NvcX02PZJqz5lDjASmDsp/V0Y8i0=";
  };

  doCheck = false;

  pyproject = true;
  nativeBuildInputs = [
    setuptools
    wheel
    (python3Packages.setuptools_scm.overridePythonAttrs (old: rec {
      version = "2.1.0";
      src = fetchPypi {
        pname = "setuptools_scm";
        inherit version;
        sha256 = "sha256-p2cUH+zascCzyOTHiKyRLXyUoNbEUtQHd7qE+RgxY3k=";
      };
    }))
  ];

  propagatedBuildInputs = [
    colorama
  ];

  SETUPTOOLS_SCM_PRETEND_VERSION = version;

  meta = with lib; {
    description = "Unit testing framework for VHDL/SystemVerilog";
    homepage = "https://vunit.github.io";
    license = licenses.mpl20;
  };
}

