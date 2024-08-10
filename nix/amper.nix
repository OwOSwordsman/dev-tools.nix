{
  self,
  lib,
  ...
}: {
  perSystem = {
    config,
    self',
    inputs',
    pkgs,
    ...
  }: {
    packages.amper = pkgs.stdenv.mkDerivation rec {
      pname = "amper";
      version = "0.4.0";

      src = pkgs.fetchurl {
        url = "https://packages.jetbrains.team/maven/p/amper/amper/org/jetbrains/amper/cli/${version}/cli-${version}-dist.zip";
        hash = "sha256-2Chvsem8e153H+wImTghrmjN7bObhHbO5lpdrBkH9vo=";
      };

      amper_sha256 = "d8286fb1e9bc7b5e771fec08993821ae68cdedb39b8476cee65a5dac1907f6fa";

      buildInputs = with pkgs; [unzip jre makeWrapper];

      buildPhase = ''
        runHook preBuild

        mkdir -p $out/bin
        unzip ${src} -d $out
        makeWrapper ${pkgs.jre}/bin/java $out/bin/amper \
          --add-flags "-ea" \
          --add-flags "-Damper.wrapper.dist.sha256=${amper_sha256}" \
          --add-flags "-Damper.wrapper.process.name=${pname}" \
          --add-flags "-cp" \
          --add-flags "\"$out/lib/*\"" \
          --add-flags "org.jetbrains.amper.cli.MainKt"

        runHook postBuild
      '';
    };
  };
}
