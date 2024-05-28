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

        py = pkgs.python3.withPackages (p: with p;[
          pip
          pyroute2
          future
          msgpack
          twisted
          pyserial
        ]);

        # Target platform libraries
        buildInputs = with pkgs;[
          libpcap
          libsodium
        ];

        # Host platform tools
        nativeBuildInputs = with pkgs; [
          py
          clang
          virtualenv
          pkg-config
          dpkg
          autoPatchelfHook
        ];

        propogatedBuildInputs = with pkgs; [
         iw
         py
        ];

      in rec {
        # Systemd unit
        # nixosModules.themis = import ./module.nix packages.default;

        # For `nix build` & `nix run`:
        packages.default = pkgs.stdenv.mkDerivation {
          name = "wfb-ng";
          src = ./.;
          inherit buildInputs nativeBuildInputs propogatedBuildInputs;

          buildPhase = ''
          make deb
          '';

          installPhase = ''
          dpkg-deb -x $src .
          mkdir -p $out/bin
          '';
        };

        # For `nix develop`:
        devShell = pkgs.mkShell {
          inherit buildInputs nativeBuildInputs propogatedBuildInputs;
        };
      });
}
