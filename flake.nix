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
          pname = "jdtls";
          version = "1.27.1";
          timestamp = "202309140221";

          src = pkgs.fetchurl {
            url = "https://download.eclipse.org/jdtls/milestones/${version}/jdt-language-server-${version}-${timestamp}.tar.gz";
            sha256 = "sha256-iGarmMlVflTmi949+LJ/seSgw6F4Wn+OFszyZ7xbWsU=";
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
              --set PATH ${pkgs.lib.makeBinPath [pkgs.jdk17_headless pkgs.python3Minimal]}
          '';

          dontUnpack = true;
          dontPatch = true;
          dontConfigure = true;
        };

        packages.junit = pkgs.stdenv.mkDerivation rec {
          pname = "junit";
          version = "1.10.0";

          jar = pkgs.fetchurl {
            url = "https://repo1.maven.org/maven2/org/junit/platform/junit-platform-console-standalone/${version}/junit-platform-console-standalone-${version}.jar";
            sha512 = "sha512-+u85hTmiZLBg4tdrl0WNQrZVV3QDAbAuGx/t3pjp9nJ52lM1MTDHpxV8KEFXDMcZToLgTnzjIE6saTyKoHRPeg==";
          };

          nativeBuildInputs = with pkgs; [makeWrapper];

          installPhase = ''
            mkdir -p $out/bin $out/libexec/junit
            cp ${jar} $out/libexec/junit/junit-platform-console-standalone.jar
            makeWrapper ${pkgs.jdk17_headless}/bin/java $out/bin/junit \
              --add-flags "-jar" \
              --add-flags "$out/libexec/junit/junit-platform-console-standalone.jar"
          '';

          dontUnpack = true;
          dontPatch = true;
          dontConfigure = true;
        };

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [python3 python3Packages.icecream];
        };
      }
    );
}
