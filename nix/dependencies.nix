{pkgs, ...}: rec {
  nativeBuildInputs = with pkgs; [
    nodejs
  ];

  buildInputs = with pkgs; [
    nurl
  ];

  all = nativeBuildInputs ++ buildInputs;
}
