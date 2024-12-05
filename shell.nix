let
  pkgs = import <nixpkgs> {};

  python = pkgs.python3.override {
    self = python;
    packageOverrides = pyfinal: pyprev: {
      vunit_hdl = pyfinal.callPackage ./vunit_hdl.nix { };
      yowasp-yosys = pyfinal.callPackage ./yowasp_yosys.nix { };
      yowasp-runtime = pyfinal.callPackage ./yowasp_runtime.nix { };
      wasmtime = pyfinal.callPackage ./wasmtime.nix { };
    };
  };

in pkgs.mkShell {
  packages = [
    (python.withPackages (python-pkgs: [
      python-pkgs.vunit_hdl
      python-pkgs.edalize
      python-pkgs.yowasp-yosys
      python-pkgs.cocotb
    ]))
    pkgs.verilator
    pkgs.gnumake
    pkgs.verible
    pkgs.gtkwave
    pkgs.zlib # verilator gtkwave
    pkgs.zlib.dev # verilator gtkwave
  ];
}

