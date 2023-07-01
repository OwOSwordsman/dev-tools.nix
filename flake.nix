{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    nixpkgs,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          inherit system;
        };
      in {
        packages.jdtls = pkgs.stdenv.mkDerivation rec {
          pname = "jdt-language-server";
          version = "1.25.0";
          timestamp = "202306291518";

          src = pkgs.fetchurl {
            url = "https://download.eclipse.org/jdtls/milestones/${version}/jdt-language-server-${version}-${timestamp}.tar.gz";
            sha256 = "sha256-1MGncYKCA26fXdxlOyXSqT/uMX4KnBWD2FsDg4uG07I=";
          };

          nativeBuildInputs = with pkgs; [makeWrapper];

          buildPhase = ''
            mkdir -p jdt-language-server
            tar xfz $src -C jdt-language-server
          '';

          installPhase = ''
            mkdir -p $out/bin $out/libexec
            cp -a jdt-language-server $out/libexec
            makeWrapper $out/libexec/jdt-language-server/bin/jdtls $out/bin/jdtls \
              --prefix PATH : ${pkgs.lib.makeBinPath [pkgs.jdk pkgs.python3Minimal]}
          '';

          dontUnpack = true;
          dontPatch = true;
          dontConfigure = true;
        };

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [python3];
        };
      }
    );
}
