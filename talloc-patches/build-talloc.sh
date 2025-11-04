#!/bin/bash

set -e

# Usage: ./build-talloc.sh <architecture> <api_level>
ARCH=$1
API_LEVEL=${2:-21}
TALLOC_VERSION="2.4.0"

echo "Building talloc $TALLOC_VERSION for $ARCH with API $API_LEVEL"

# Set compiler based on architecture
case "$ARCH" in
    "arm64-v8a"|"aarch64")
        CLANG_NAME="aarch64-linux-android${API_LEVEL}-clang"
        ;;
    "armeabi-v7a"|"armv7a")
        CLANG_NAME="armv7a-linux-androideabi${API_LEVEL}-clang"
        ;;
    "x86_64")
        CLANG_NAME="x86_64-linux-android${API_LEVEL}-clang"
        ;;
    "x86"|"i686")
        CLANG_NAME="i686-linux-android${API_LEVEL}-clang"
        ;;
    *)
        echo "Unknown architecture: $ARCH"
        exit 1
        ;;
esac

export CC="$TOOLCHAIN/bin/$CLANG_NAME"
export AR="$TOOLCHAIN/bin/llvm-ar"
export RANLIB="$TOOLCHAIN/bin/llvm-ranlib"
export STRIP="$TOOLCHAIN/bin/llvm-strip"
export CFLAGS="-fPIC -D_GNU_SOURCE -O2 -I."

echo "Using compiler: $CC"

# Download talloc if not present
if [ ! -d "talloc-$TALLOC_VERSION" ]; then
    echo "Downloading talloc $TALLOC_VERSION..."
    wget -q https://www.samba.org/ftp/talloc/talloc-$TALLOC_VERSION.tar.gz
    tar -xzf talloc-$TALLOC_VERSION.tar.gz
    rm talloc-$TALLOC_VERSION.tar.gz
fi

cd talloc-$TALLOC_VERSION

# Copy our headers
cp ../talloc-patches/config.h .
cp ../talloc-patches/replace.h .

# Compile talloc directly
echo "Compiling talloc..."
$CC $CFLAGS -c talloc.c -o talloc.o

# Create static library
echo "Creating library..."
$AR rcs libtalloc.a talloc.o
$RANLIB libtalloc.a

# Create install directory
INSTALL_DIR="../install/$ARCH"
mkdir -p $INSTALL_DIR/lib
mkdir -p $INSTALL_DIR/include
mkdir -p $INSTALL_DIR/lib/pkgconfig

# Copy files
cp libtalloc.a $INSTALL_DIR/lib/
cp talloc.h $INSTALL_DIR/include/
cp config.h $INSTALL_DIR/include/

# Create pkg-config file
cat > $INSTALL_DIR/lib/pkgconfig/talloc.pc << EOF
prefix=/usr
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include

Name: talloc
Description: hierarchical memory allocator
Version: $TALLOC_VERSION
Libs: -L\${libdir} -ltalloc
Cflags: -I\${includedir}
EOF

# Verify build
echo "Verifying build..."
file $INSTALL_DIR/lib/libtalloc.a
$AR t $INSTALL_DIR/lib/libtalloc.a

echo "Build successful! Library installed in $INSTALL_DIR"
