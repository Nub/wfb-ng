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

        wfb_cfg = pkgs.writeText "wifibroadcast.cfg" ''
        [common]
        wifi_channel = 161     # 161 -- radio channel @5825 MHz, range: 5815–5835 MHz, width 20MHz
                               # 1 -- radio channel @2412 Mhz, 
                               # see https://en.wikipedia.org/wiki/List_of_WLAN_channels for reference
        wifi_region = 'BO'     # Your country for CRDA (use BO or GY if you want max tx power)  

        [gs_mavlink]
        peer = 'connect://127.0.0.1:14550'  # outgoing connection
        # peer = 'listen://0.0.0.0:14550'   # incoming connection

        [gs_video]
        peer = 'connect://127.0.0.1:5600'  # outgoing connection for
                                           # video sink (QGroundControl on GS)
        '';

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
           wfb_cfg
          ];

          buildPhase = ''
          make 
          '';

          installPhase = ''
          mkdir -p $out/bin
          cp wfb_rx $out/bin
          cp wfb_tx $out/bin
          cp wfb_keygen $out/bin

          mkdir -p $out/etc
          cp ${wfb_cfg} $out/etc/wifibroadcast.cfg
          '';
        };


      in rec {
        # Systemd unit
        # nixosModules.themis = import ./module.nix packages.default;

        # For `nix build` & `nix run`:
        packages.default = wfb-cli;

        # For `nix develop`:
        devShell = pkgs.mkShell {
          nativeBuildInputs = [wfb-cli wfb-ng pkgs.iw];
        };
      });
}
