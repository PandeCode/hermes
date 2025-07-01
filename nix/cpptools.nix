{
  stdenv,
  fetchurl,
}: (stdenv.mkDerivation rec {
  pname = "cpptools";
  version = "1.26.3";
  src = fetchurl {
    url = "https://github.com/microsoft/vscode-cpptools/releases/download/v${version}/cpptools-linux-x64.vsix";
    sha256 = "2444b97ac556e9c465ae614040ed722d81196cb750bb820b5b4ae30c1a79124e";
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
