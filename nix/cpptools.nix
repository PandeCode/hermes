{
  stdenv,
  unzip,
  fetchurl,
}: (stdenv.mkDerivation {
  pname = "cpptools";
  version = "v1.22.1";
  nativeBuildInputs = [unzip];
  src = fetchurl {
    url = "https://github.com/microsoft/vscode-cpptools/releases/download/v1.22.11/cpptools-linux-x64.vsix";
    sha256 = "93ec1b4d9be83e6b0a28cebbf441cc84ee0f6d47b56a677f5cb54e27a929c0f3";
  };
  phases = ["unpackPhase" "installPhase"];
  unpackPhase = ''
    mkdir -p $out/bin
    unzip $src
  '';
  installPhase = ''
    chmod +x extension/debugAdapters/bin/OpenDebugAD7
    mv extension $out/
    ln -s $out/extension/debugAdapters/bin/OpenDebugAD7 $out/bin/OpenDebugAD7
  '';
})
