#!/bin/bash

set -e

BUILD=${BUILD:-`gcc -dumpmachine`}
TARGET=${TARGET:-arm-none-eabi}

AUTOCONF=${AUTOCONF:-autoconf-2.64}
NEWLIB=${NEWLIB:-newlib-2.5.0}
BINUTILS=${BINUTILS:-binutils-2.29.1}
GCC=${GCC:-gcc-7.2.0}
GDB=${GDB:-gdb-8.0.1}
EXPAT_VERSION=${EXPAT:-2.2.5}
EXPAT=${EXPAT:-expat-${EXPAT_VERSION}}

NPROC=${NPROC:-$((`nproc`*2))}
PARALLEL=${PARALLEL:--j${NPROC}}

PATH=/gcc-bootstrap/bin:/gcc-toolchain/bin:$PATH;export PATH
LD_LIBRARY_PATH=/gcc-toolchain/lib:$LD_LIBRARY_PATH;export LD_LIBRARY_PATH
LD_RUN_PATH=/gcc-toolchain/lib:$LD_RUN_PATH;export LD_RUN_PATH

echo "# ==============================================================="
echo "# download"

mkdir -p artifacts
cd artifacts

if [ ! -f ${AUTOCONF}.tar.bz2 ] ; then
    wget http://ftpmirror.gnu.org/autoconf/${AUTOCONF}.tar.bz2
fi
if [ ! -f ${BINUTILS}.tar.bz2 ] ; then
    wget http://ftpmirror.gnu.org/binutils/${BINUTILS}.tar.bz2
fi
if [ ! -f ${GCC}.tar.gz ] ; then
    wget http://ftpmirror.gnu.org/gcc/${GCC}/${GCC}.tar.gz
fi
if [ ! -f ${GDB}.tar.gz ] ; then
    wget http://ftpmirror.gnu.org/gdb/${GDB}.tar.gz
fi
if [ ! -f ${EXPAT}.tar.bz2 ] ; then
    wget https://github.com/libexpat/libexpat/releases/download/R_${EXPAT_VERSION//\./_}/${EXPAT}.tar.bz2
fi
if [ ! -f ${NEWLIB}.tar.gz ] ; then
    wget http://sourceware.org/pub/newlib/${NEWLIB}.tar.gz
fi

cd ..

echo "# ==============================================================="
echo "# extract"

mkdir -p stage
cd stage

if [ ! -d ${AUTOCONF} ] ; then
    echo "Extracting: ${AUTOCONF}"
    tar -jxf ../artifacts/${AUTOCONF}.tar.bz2
fi
if [ ! -d ${NEWLIB} ] ; then
    echo "Extracting: ${NEWLIB}"
    tar -zxf ../artifacts/${NEWLIB}.tar.gz

    # Patching reentrancy
    echo 'newlib_cflags="${newlib_cflags} -DREENTRANT_SYSCALLS_PROVIDED"' >> ${NEWLIB}/newlib/configure.host
fi
if [ ! -d ${BINUTILS} ] ; then
    echo "Extracting: ${BINUTILS}"
    tar -jxf ../artifacts/${BINUTILS}.tar.bz2
fi
if [ ! -d ${GCC} ] ; then
    echo "Extracting: ${GCC}"
    tar -zxf ../artifacts/${GCC}.tar.gz
fi
if [ ! -d ${EXPAT} ] ; then
    echo "Extracting: ${EXPAT}"
    tar -jxf ../artifacts/${EXPAT}.tar.bz2
fi
if [ ! -d ${GDB} ] ; then
    echo "Extracting: ${GDB}"
    tar -zxf ../artifacts/${GDB}.tar.gz
fi

echo "# ==============================================================="
echo "# download and extract by gcc's prerequisities"

cd ${GCC}
contrib/download_prerequisites --directory=..
cd ..

rm *.bz2
rm *.gz

echo "# ==============================================================="
echo "# remove last toolchains"

rm -rf /gcc-bootstrap
rm -rf /gcc-toolchain

# ==========================================================================
# bootstrap builds

echo "# ==============================================================="
echo "# autoconf"

cd autoconf*

rm -rf build
mkdir -p build
cd build
../configure --prefix=/gcc-bootstrap
make ${PARALLEL}
make install
# Autoconf's test too long
#make ${PARALLEL} check
cd ..

cd ..

echo "# ==============================================================="
echo "# binutils (bootstrap1)"

cd binutils*
autoconf

rm -rf build-bootstrap1
mkdir -p build-bootstrap1
cd build-bootstrap1
../configure --prefix=/gcc-bootstrap \
    --disable-nls \
    --disable-werror \
    --disable-shared \
    --enable-gold \
    --enable-lto \
    --enable-multilib \
    --enable-interwork \
    --enable-vtable-verify \
    --with-newlib \
    --with-isl
make ${PARALLEL}
make install
cd ..

cd ..

echo "# ==============================================================="
echo "# gcc (bootstrap1)"

cd gcc*

rm -rf build-bootstrap1
mkdir -p build1-bootstrap1
cd build1-bootstrap1
../configure --prefix=/gcc-bootstrap \
    --disable-nls \
    --disable-werror \
    --disable-shared \
    --disable-libssp \
    --disable-libquadmath \
    --enable-lto \
    --enable-multilib \
    --enable-interwork \
    --with-newlib \
    --with-gmp \
    --with-mpfr \
    --with-mpc \
    --with-isl \
    --enable-languages=c
make ${PARALLEL}
make install
cd ..

cd ..

echo "# ==============================================================="
echo "# newlib (bootstrap)"

cd newlib*

rm -rf build
mkdir -p build
cd build
../configure --prefix=/gcc-bootstrap \
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
make ${PARALLEL} check
cd ..

cd ..

echo "# ==============================================================="
echo "# gmp (bootstrap)"

cd gmp*

rm -rf build
mkdir -p build
cd build
../configure --prefix=/gcc-bootstrap \
    --disable-shared
make ${PARALLEL}
make install
make ${PARALLEL} check
cd ..

cd ..

echo "# ==============================================================="
echo "# mpfr (bootstrap)"

cd mpfr*

rm -rf build
mkdir -p build
cd build
../configure --prefix=/gcc-bootstrap \
    --disable-shared \
    --with-gmp=/gcc-bootstrap
make ${PARALLEL}
make install
make ${PARALLEL} check
cd ..

cd ..

echo "# ==============================================================="
echo "# mpc (bootstrap)"

cd mpc*

rm -rf build
mkdir -p build
cd build
../configure --prefix=/gcc-bootstrap \
    --disable-shared \
    --with-gmp=/gcc-bootstrap \
    --with-mpfr=/gcc-bootstrap
make ${PARALLEL}
make install
make ${PARALLEL} check
cd ..

cd ..

echo "# ==============================================================="
echo "# isl (bootstrap)"

cd isl*

rm -rf build
mkdir -p build
cd build
../configure --prefix=/gcc-bootstrap \
    --disable-shared \
    --with-gmp-prefix=/gcc-bootstrap
make ${PARALLEL}
make install
make ${PARALLEL} check
cd ..

cd ..

echo "# ==============================================================="
echo "# expat (bootstrap)"

cd expat*

rm -rf build
mkdir -p build
cd build
../configure --prefix=/gcc-toolchain \
    --disable-shared
make ${PARALLEL}
make install
make ${PARALLEL} check
cd ..

cd ..

echo "# ==============================================================="
echo "# binutils (bootstrap2)"

cd binutils*

rm -rf build-bootstrap2
mkdir -p build-bootstrap2
cd build-bootstrap2
../configure --prefix=/gcc-bootstrap \
    --disable-nls \
    --disable-werror \
    --disable-shared \
    --enable-gold \
    --enable-lto \
    --enable-multilib \
    --enable-interwork \
    --enable-vtable-verify \
    --with-newlib \
    --with-isl
make ${PARALLEL}
make install
make ${PARALLEL} check
cd ..

cd ..

echo "# ==============================================================="
echo "# gcc (bootstrap2)"

cd gcc*

rm -rf build-bootstrap2
mkdir -p build1-bootstrap2
cd build1-bootstrap2
../configure --prefix=/gcc-bootstrap \
    --disable-nls \
    --disable-werror \
    --disable-shared \
    --disable-libssp \
    --disable-libquadmath \
    --enable-lto \
    --enable-multilib \
    --enable-interwork \
    --with-newlib \
    --with-gmp \
    --with-mpfr \
    --with-mpc \
    --with-isl \
    --with-headers=../../${NEWLIB}/newlib/libc/include \
    --enable-languages=c
make ${PARALLEL}
make install
make ${PARALLEL} check
cd ..

cd ..

# ==========================================================================
# cross builds

echo "# ==============================================================="
echo "# binutils (for ${BUILD} --> ${TARGET})"

cd binutils*

rm -rf build-${TARGET}
mkdir -p build-${TARGET}
cd build-${TARGET}
../configure --prefix=/gcc-toolchain \
    --target=${TARGET} \
    --disable-nls \
    --disable-werror \
    --disable-shared \
    --enable-gold \
    --enable-lto \
    --enable-multilib \
    --enable-interwork \
    --enable-vtable-verify \
    --with-newlib \
    --with-isl=/gcc-toolchain
make ${PARALLEL}
make install
make ${PARALLEL} check
cd ..

cd ..

echo "# ==============================================================="
echo "# gcc (only C for ${BUILD} --> ${TARGET})"

cd gcc*

rm -rf build-${TARGET}1
mkdir -p build-${TARGET}1
cd build-${TARGET}1
../configure --prefix=/gcc-toolchain \
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
echo "# newlib (for ${BUILD} --> ${TARGET})"

cd newlib*

rm -rf build-${TARGET}
mkdir -p build-${TARGET}
cd build-${TARGET}
../configure --prefix=/gcc-toolchain \
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
make ${PARALLEL} check
cd ..

cd ..

echo "# ==============================================================="
echo "# gcc (for ${BUILD} --> ${TARGET})"

cd gcc*

rm -rf build-${TARGET}2
mkdir -p build-${TARGET}2
cd build-${TARGET}2
../configure --prefix=/gcc-toolchain \
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
echo "# gdb (for ${BUILD} --> ${TARGET})"

cd gdb*

rm -rf build-${TARGET}
mkdir -p build-${TARGET}
cd build-${TARGET}
../configure --prefix=/gcc-toolchain \
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
    --enable-expat \
    --with-expat \
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

echo "# ==============================================================="
echo "# collect"

COLLECT=`pwd`/../artifacts/gcc-toolchain_${BUILD}_${TARGET}.tar.bz2
pushd /
tar -jcvf ${COLLECT} gcc-toolchain
popd
