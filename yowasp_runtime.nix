# yowasp_runtime.nix
{ lib
, buildPythonPackage
, fetchurl
, setuptools
, wheel
, wasmtime
, platformdirs
}:

buildPythonPackage rec {
  pname = "yowasp-runtime";
  version = "1.65";

  format = "wheel";
  dist = "py3";
  python = "py3";

  src = fetchurl {
    url = "https://files.pythonhosted.org/packages/py3/y/yowasp-runtime/yowasp_runtime-${version}-py3-none-any.whl";
    sha256 = "sha256-gt9dfWmzZxTR2hgbptKak/GOBcIUiSfcPoSW3P5zjIA=";
  };

  nativeBuildInputs = [
    setuptools
    wheel
  ];
  
  propagatedBuildInputs = [
    wasmtime
    platformdirs
  ];

  meta = with lib; {
    description = "YoWASP runtime support package";
    homepage = "https://yowasp.org";
    license = licenses.isc;
  };
}

