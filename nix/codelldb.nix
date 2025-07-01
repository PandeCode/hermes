{
  stdenv,
  fetchurl,
}: (stdenv.mkDerivation rec {
  pname = "codelldb";
  version = "1.11.5";
  src = fetchurl {
    url = "https://github.com/vadimcn/codelldb/releases/download/v${version}/codelldb-linux-x64.vsix";
    sha256 = "0y09q8ssyrayyaxpvmsdip25lccg543gw8haf3jq0yxlh2pky88p";
  };
  phases = ["unpackPhase" "installPhase"];
  unpackPhase = ''
    mkdir -p $out/bin
    unzip $src
  '';
  installPhase = ''
    chmod +x extension/adapter/codelldb
    mv extension $out/
    ln -s $out/extension/adapter/codelldb $out/bin/codelldb
  '';
})
