{
  description = "Jonathan Lorimer's NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    pypiFetcherSrc.url = "github:DavHau/nix-pypi-fetcher";
    pypiFetcherSrc.flake = false;
    chaos-src.url = "github:jonnyhyman/Chaos";
    chaos-src.flake = false;
  };
  outputs =
    { nixpkgs
    , flake-utils
    , chaos-src
    , pypiFetcherSrc
    , ...
    }:
    with flake-utils.lib;
    eachDefaultSystem (system:
      let
        pypiFetcher = (import pypiFetcherSrc {inherit pkgs; fetcherSrc = pypiFetcherSrc; }).fetchPypi;
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            (final: prev: {
              python38 = prev.python38.override {
                packageOverrides = python-final: python-prev: {
                  vispy = python-prev.vispy.overrideAttrs (_: {
                    src = pypiFetcher "vispy" "0.6.4";
                    name = "vispy-0.6.4";
                  });
                };
              };
            })
          ];
        };
      in rec {
        packages =
          let chaosPython =
              pkgs.python38.withPackages(ps: with ps; [
                # Universal dependencies
                numpy
                numba
                pyqt5
                pyqtgraph

                # Mandelbrot dependencies
                vispy
                matplotlib
                pyopengl
              ]);
              mkChaosApp = name: pythonFilePath:
                pkgs.writeShellApplication {
                  name = "chaos";
                  runtimeInputs = [chaosPython pkgs.libsForQt5.qt5.qtbase pkgs.ffmpeg];
                  text = "python ${chaos-src}/${pythonFilePath}";
                };
          in
          {
            interactive = mkChaosApp "interactive" "logistic_interactive.py";
            mandelbrot = mkChaosApp "mandelbrot" "logistic_mandelbrot.py";
            zoom = mkChaosApp "zoom" "logistic_zoom.py";
          };
        apps = {
          chaos-interactive = mkApp { drv = packages.interactive; };
          chaos-mandelbrot = mkApp { drv = packages.mandelbrot; };
          chaos-zoom = mkApp { drv = packages.zoom; };
        };

        devShell = pkgs.mkShell {
          buildInputs = [] ++ builtins.attrValues packages;
        };
      }
    );
}
