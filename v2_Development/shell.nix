with import <nixpkgs> {};
with luaPackages;

let
  libs = [
      conntrack-tools
      openssl
      ninja
      libpcap
      lua5_1
      luasocket
      luasec
      cjson
      nettools
      psutils
      gcc
      taglib
      git
      libxml2
      libxslt
      libzip
      zlib
  ];
in
stdenv.mkDerivation rec {
  name = "madcat";
  buildInputs = libs;
  nativeBuildInputs = [ cmake ];
  shellHook = ''
    export LD_LIBRARY_PATH=$(nix eval --raw nixpkgs.lua5_1)/include:$LD_LIBRARY_PATH
    export C_INCLUDE_PATH="$PWD/include:$PWD/include/rsp:$(nix eval --raw nixpkgs.lua5_1)/include"
    #export LUA_CPATH="${lib.concatStringsSep ";" (map getLuaCPath libs)}"
    #export LUA_PATH="${lib.concatStringsSep ";" (map getLuaPath libs)}"
    # Check first if build directory exists already
    if [ -d "build" ]; then
      rm -rf build
    fi
    cmake -Bbuild
    cd build
    make
  '';
}
