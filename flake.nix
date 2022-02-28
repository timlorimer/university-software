{
  description = "Jonathan Lorimer's NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    chaos-src.url = "github:jonnyhyman/Chaos";
    chaos-src.flake = false;
  };
  outputs =
    { nixpkgs
    , flake-utils
    , chaos-src
    , ...
    }: 
    with flake-utils.lib;
    eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in rec { 
        packages = {
          chaos = 
            let chaosPython = 
                pkgs.python39.withPackages(ps: with ps; [ 
                  numpy 
                  numba 
                  pyqt5 
                  pyqtgraph
                ]);
            in pkgs.writeShellApplication {
                name = "chaos";
                runtimeInputs = [ chaosPython pkgs.libsForQt5.qt5.qtbase];
                text = "python ${chaos-src}/logistic_interactive.py";
             };
        };

        apps = {
          chaos = mkApp { drv = packages.chaos; };
        };

        devShell = pkgs.mkShell {
          buildInputs = [] ++ builtins.attrValues packages;
        };
      }
    );
}
