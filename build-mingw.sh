#!/bin/bash

set -e

BUILD=${BUILD:-i686-pc-mingw32}
TARGET=${TARGET:-arm-none-eabi}

AUTOCONF=${AUTOCONF:-autoconf-2.64}
NEWLIB=${NEWLIB:-newlib-2.5.0}
BINUTILS=${BINUTILS:-binutils-2.29.1}
GCC=${GCC:-gcc-7.2.0}
GDB=${GDB:-gdb-8.0.1}

# MSYS environments unstable on parallel make.
#NPROC=${NPROC:-$((`nproc`*2))}
#PARALLEL=${PARALLEL:--j${NPROC}}
PARALLEL=

PATH=/gcc-toolchain/bin:$PATH;export PATH
LD_LIBRARY_PATH=/gcc-toolchain/lib:$LD_LIBRARY_PATH;export LD_LIBRARY_PATH
LD_RUN_PATH=/gcc-toolchain/lib:$LD_RUN_PATH;export LD_RUN_PATH

NEWLIB_CFLAGS=-DREENTRANT_SYSCALLS_PROVIDED;export NEWLIB_CFLAGS

echo "# ==============================================================="
echo "# download"

mkdir stage
mkdir artifacts
cd artifacts

if [ ! -f ${AUTOCONF}.tar.bz2 ] ; then
    wget http://ftp.gnu.org/gnu/autoconf/${AUTOCONF}.tar.bz2
    (cd ../stage; tar -jxf ../artifacts/${AUTOCONF}.tar.bz2 )
fi
if [ ! -f ${NEWLIB}.tar.gz ] ; then
    wget ftp://sourceware.org/pub/newlib/${NEWLIB}.tar.gz
    (cd ../stage; tar -zxf ../artifacts/${NEWLIB}.tar.gz )
fi
if [ ! -f ${BINUTILS}.tar.bz2 ] ; then
    wget ftp://sourceware.org/pub/binutils/snapshots/${BINUTILS}.tar.bz2
    (cd ../stage; tar -jxf ../artifacts/${BINUTILS}.tar.bz2 )
fi
if [ ! -f ${GCC}.tar.gz ] ; then
    wget ftp://ftp.gnu.org/gnu/gcc/${GCC}/${GCC}.tar.gz
    (cd ../stage; tar -zxf ../artifacts/${GCC}.tar.gz )
fi
if [ ! -f ${GDB}.tar.gz ] ; then
    wget http://ftp.gnu.org/gnu/gdb/${GDB}.tar.gz
    (cd ../stage; tar -zxf ../artifacts/${GDB}.tar.gz )
fi

cd ..
cd stage

cd ${GCC}
contrib/download_prerequisites --no-verify --directory=..
cd ..

mv *.bz2 ../artifacts
mv *.gz ../artifacts

rm -rf build
mkdir build
cd build

echo "# ==============================================================="
echo "# gmp"

cd gmp*

mkdir build
cd build
../configure --prefix=/gcc-toolchain \
    --disable-shared \
    --build=${BUILD}
make ${PARALLEL}
make install
make ${PARALLEL} check
cd ..

cd ..

echo "# ==============================================================="
echo "# mpfr"

cd mpfr*

mkdir build
cd build
../configure --prefix=/gcc-toolchain \
    --disable-shared \
    --build=${BUILD} \
    --with-gmp=/gcc-toolchain
make ${PARALLEL}
make install
make ${PARALLEL} check
cd ..

cd ..

echo "# ==============================================================="
echo "# mpc"

cd mpc*

mkdir build
cd build
../configure --prefix=/gcc-toolchain \
    --disable-shared \
    --build=${BUILD} \
    --with-gmp=/gcc-toolchain \
    --with-mpfr=/gcc-toolchain
make ${PARALLEL}
make install
make ${PARALLEL} check
cd ..

cd ..

echo "# ==============================================================="
echo "# autoconf"

cd autoconf*

mkdir build
cd build
../configure --prefix=/gcc-toolchain
make ${PARALLEL}
make install
# Autoconf's test too long
#make ${PARALLEL} check
cd ..

cd ..

echo "# ==============================================================="
echo "# binutils"

cd binutils*
autoconf

mkdir build
cd build
../configure --prefix=/gcc-toolchain \
    --build=${BUILD} \
    --target=${TARGET} \
    --disable-nls \
    --disable-werror \
    --disable-shared \
    --enable-gold \
    --enable-lto \
    --enable-multilib \
    --enable-interwork \
    --enable-objc-gc \
    --enable-vtable-verify \
    --with-newlib \
    --with-isl=/gcc-toolchain
make ${PARALLEL}
make install
# binutils may fail if enable parallel checking.
#make ${PARALLEL} check
make check
cd ..

cd ..

echo "# ==============================================================="
echo "# gcc (1)"

cd gcc*

mkdir build
cd build
../configure --prefix=/gcc-toolchain \
    --build=${BUILD} \
    --target=${TARGET} \
    --disable-nls \
    --disable-werror \
    --disable-shared \
    --disable-libssp \
    --disable-libquadmath \
    --enable-lto \
    --enable-multilib \
    --enable-interwork \
    --with-newlib \
    --with-gmp=/gcc-toolchain \
    --with-mpfr=/gcc-toolchain \
    --with-mpc=/gcc-toolchain \
    --with-isl=/gcc-toolchain \
    --with-headers=../../${NEWLIB}/newlib/libc/include \
    --enable-languages=c
make ${PARALLEL}
make install
make ${PARALLEL} check
cd ..

cd ..

echo "# ==============================================================="
echo "# newlib"

cd newlib*

mkdir build
cd build
../configure --prefix=/gcc-toolchain \
    --build=${BUILD} \
    --target=${TARGET} \
    --disable-nls \
    --disable-werror \
    --disable-shared \
    --disable-libssp \
    --enable-lto \
    --enable-multilib \
    --enable-interwork \
    --enable-vtable-verify
make ${PARALLEL}
make install
cd ..

cd ..

echo "# ==============================================================="
echo "# gcc (2)"

cd gcc*

mkdir build
cd build
../configure --prefix=/gcc-toolchain \
    --build=${BUILD} \
    --target=${TARGET} \
    --disable-nls \
    --disable-werror \
    --disable-shared \
    --disable-libssp \
    --enable-gold \
    --enable-lto \
    --enable-multilib \
    --enable-interwork \
    --enable-vtable-verify \
    --with-newlib \
    --with-gmp=/gcc-toolchain \
    --with-mpfr=/gcc-toolchain \
    --with-mpc=/gcc-toolchain \
    --with-isl=/gcc-toolchain \
    --with-headers=../../${NEWLIB}/newlib/libc/include \
    --enable-languages=c,c++
make ${PARALLEL}
make install
make ${PARALLEL} check
cd ..

cd ..

echo "# ==============================================================="
echo "# gdb"

cd gdb*

mkdir build
cd build
../configure --prefix=/gcc-toolchain \
    --build=${BUILD} \
    --target=${TARGET} \
    --disable-nls \
    --disable-werror \
    --disable-shared \
    --disable-libssp \
    --enable-gold \
    --enable-lto \
    --enable-multilib \
    --enable-interwork \
    --enable-vtable-verify \
    --with-newlib \
    --with-gmp=/gcc-toolchain \
    --with-mpfr=/gcc-toolchain \
    --with-mpc=/gcc-toolchain \
    --with-isl=/gcc-toolchain
make ${PARALLEL}
make install
make ${PARALLEL} check
cd ..

cd ..
