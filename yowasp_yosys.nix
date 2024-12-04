{ lib
, buildPythonPackage
, fetchurl
, setuptools
, wheel
, yowasp-runtime
}:

buildPythonPackage rec {
  pname = "yowasp-yosys";
  version = "0.47.0.0.post805";

  format = "wheel";
  dist = "py3";
  python = "py3";

  src = fetchurl {
    url = "https://files.pythonhosted.org/packages/py3/y/yowasp-yosys/yowasp_yosys-${version}-py3-none-any.whl";
    sha256 = "sha256-g5dYu9vV4t44dCz3uaMTaOY7O7wNdIa3KZZbFIlzhLA=";
  };

  nativeBuildInputs = [
    setuptools
    wheel
  ];

  propagatedBuildInputs = [
    yowasp-runtime
  ];

  meta = with lib; {
    description = "YoWASP distribution of the Yosys synthesis suite";
    homepage = "https://yowasp.org";
    license = licenses.isc;
  };
}

