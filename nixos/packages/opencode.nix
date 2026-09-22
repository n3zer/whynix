{ pkgs }:

pkgs.stdenv.mkDerivation {
  pname = "opencode";
  version = "1.18.31";

  src = pkgs.fetchurl {
    url = "https://github.com/anomalyco/opencode/releases/download/v1.18.31/opencode-linux-x64-baseline.tar.gz";
    hash = "sha256-soPo2+nm/CJLtLeZks470hdLi3sMPn0bTmAkodEe3IQ=";
  };

  dontUnpack = true;
  dontBuild = true;
  dontStrip = true;
  dontPatchELF = true;

  installPhase = ''
    mkdir -p $out/bin
    tar -xzf $src -C $out/bin
    chmod +x $out/bin/opencode
  '';
}
