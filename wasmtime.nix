# wasmtime.nix
{ lib
, buildPythonPackage
, fetchurl
, setuptools
, wheel
}:

buildPythonPackage rec {
  pname = "wasmtime";
  version = "25.0.0";

  format = "wheel";
  dist = "py3";
  python = "py3";

  src = fetchurl {
    url = "https://files.pythonhosted.org/packages/py3/w/wasmtime/wasmtime-${version}-py3-none-manylinux1_x86_64.whl";
    sha256 = "sha256-tDZOFNROO3r+akC/YI6dDSxAsJ3s5EHSD09uMZBrcpw=";
  };

  nativeBuildInputs = [
    setuptools
    wheel
  ];

  meta = with lib; {
    description = "Python WebAssembly runtime powered by Wasmtime";
    homepage = "https://github.com/bytecodealliance/wasmtime-py";
    license = licenses.asl20;
    platforms = [ "x86_64-linux" ];
  };
}

