#!/bin/sh
set -eu
ROOT=$(CDPATH= cd -- "$1" && pwd)
cd "$ROOT"
shasum -a 256 -c SHA256SUMS
PREFIX="$ROOT/build/installed"
mkdir -p "$ROOT/build"
export CC="$(xcrun --find clang)"
export SDKROOT="$(xcrun --sdk macosx --show-sdk-path)"
export AR="$(xcrun --find ar)"
export RANLIB="$(xcrun --find ranlib)"
export CFLAGS='-O2 -mmacosx-version-min=26.0'
for NAME in libogg-1.3.5 opus-1.5.2 opusfile-0.12; do
    tar -xzf "$NAME.tar.gz" -C "$ROOT/build"
done
cd "$ROOT/build/libogg-1.3.5"
./configure --prefix="$PREFIX" --disable-shared --enable-static
make -j4
make install
cd "$ROOT/build/opus-1.5.2"
./configure --prefix="$PREFIX" --disable-shared --enable-static --disable-doc --disable-extra-programs
make -j4
make install
cd "$ROOT/build/opusfile-0.12"
export DEPS_CFLAGS="-I$PREFIX/include -I$PREFIX/include/opus"
export DEPS_LIBS="-L$PREFIX/lib -lopus -logg -lm"
./configure --prefix="$PREFIX" --disable-shared --enable-static --disable-http --disable-doc
cp include/opusfile.h "$PREFIX/include/opus/opusfile.h"
# Compile the four upstream library sources directly. The old libtool archive
# step can create nested static archives with newer Xcode tools on CI.
"$CC" -O2 -mmacosx-version-min=26.0 -DHAVE_CONFIG_H -I. -Iinclude \
    -I"$PREFIX/include" -I"$PREFIX/include/opus" \
    "$ROOT/opusdecode.c" src/info.c src/internal.c src/opusfile.c src/stream.c \
    "$PREFIX/lib/libopus.a" "$PREFIX/lib/libogg.a" -lm -o "$ROOT/opusdecode"
mkdir -p "$ROOT/licenses"
for NAME in libogg-1.3.5 opus-1.5.2 opusfile-0.12; do
    cp "$ROOT/build/$NAME/COPYING" "$ROOT/licenses/$NAME-COPYING.txt"
done
