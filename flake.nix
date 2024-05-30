{
  inputs = {
    utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/23.11";
  };

  outputs = { utils, nixpkgs, ... }:
    # Replicate this package for different build system hosts
    utils.lib.eachDefaultSystem (system:
      let
        # Select host system packages
        pkgs = nixpkgs.legacyPackages.${system};

        wfb-cli = pkgs.python3Packages.buildPythonApplication rec {
          name = "wfb_cli";
          src = ./.;
          VERSION = "0.1";
          COMMIT = "0";

          propagatedBuildInputs = with pkgs.python3Packages; [
            pyroute2
            future
            msgpack
            twisted
            pyserial
            setuptools
            wfb-ng
            pkgs.iw
          ];
          nativeBuildInputs = propagatedBuildInputs;
          buildInputs = propagatedBuildInputs;
        };

        wfb-ng = pkgs.stdenv.mkDerivation {
          name = "wfb-ng";
          src = ./.;

          # Target platform libraries
          buildInputs = with pkgs;[
            libpcap
            libsodium
          ];

          # Host platform tools
          nativeBuildInputs = with pkgs; [
            clang
            virtualenv
            pkg-config
            dpkg
            autoPatchelfHook
            git
          ];

          propogatedBuildInputs = with pkgs; [
           iw
          ];

          buildPhase = ''
          make 
          '';

          installPhase = ''
          mkdir -p $out/bin
          cp wfb_rx $out/bin
          cp wfb_tx $out/bin
          cp wfb_keygen $out/bin
          '';
        };


      in rec {
        # Systemd unit
        nixosModules.wfb = (import ./module.nix) packages.default;

        # For `nix build` & `nix run`:
        packages.default = wfb-cli;

        # For `nix develop`:
        devShell = pkgs.mkShell {
          nativeBuildInputs = [wfb-cli wfb-ng];
        };
      });
}
