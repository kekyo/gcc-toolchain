#!/bin/bash

set -e

BUILD=${BUILD:-`gcc -dumpmachine`}
SUFFIX=${SUFFIX:-`date --iso-8601`}

NEWLIB=${NEWLIB:-newlib-2.5.0}
BINUTILS=${BINUTILS:-binutils-2.29.1}
GCC=${GCC:-gcc-7.2.0}
GDB=${GDB:-gdb-8.0.1}

NPROC=${NPROC:-$((`nproc`*2))}
PARALLEL=${PARALLEL:--j${NPROC}}

PATH=/gcc-bootstrap/bin:/gcc-toolchain/bin:$PATH;export PATH
LD_LIBRARY_PATH=/gcc-bootstrap/lib:/gcc-toolchain/lib:$LD_LIBRARY_PATH;export LD_LIBRARY_PATH
LD_RUN_PATH=/gcc-bootstrap/lib:/gcc-toolchain/lib:$LD_RUN_PATH;export LD_RUN_PATH

pushd stage

BOOTSTRAP_PATH=`pwd`/gcc-bootstrap

# ==========================================================================
# cross builds

for TARGET in "$@"; do

BUILD_TARGET=${BUILD}_${TARGET}
BUILD_TARGET_NAME=build_${BUILD_TARGET}
BUILD_TARGET_PATH=`pwd`/${BUILD_TARGET_NAME}

echo "# ==============================================================="
echo "# remove last toolchains (for ${BUILD} --> ${TARGET})"

rm -rf ${BUILD_TARGET_PATH}
mkdir -p ${BUILD_TARGET_PATH}

echo "# ==============================================================="
echo "# binutils (for ${BUILD} --> ${TARGET})"

pushd binutils*

rm -rf build-${BUILD_TARGET}
mkdir -p build-${BUILD_TARGET}
cd build-${BUILD_TARGET}
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
    --with-isl=${BOOTSTRAP_PATH}
make ${PARALLEL}
make install DESTDIR=${BUILD_TARGET_PATH}
make ${PARALLEL} check

popd

echo "# ==============================================================="
echo "# gcc (only C for ${BUILD} --> ${TARGET})"

pushd gcc*

rm -rf build-${BUILD_TARGET}-1
mkdir -p build-${BUILD_TARGET}-1
cd build-${BUILD_TARGET}-1
../configure --prefix=/gcc-toolchain \
    --target=${TARGET} \
    --disable-nls \
    --disable-werror \
    --disable-shared \
    --disable-libssp \
    --enable-lto \
    --enable-multilib \
    --enable-interwork \
    --with-newlib \
    --with-gmp=${BOOTSTRAP_PATH} \
    --with-mpfr=${BOOTSTRAP_PATH} \
    --with-mpc=${BOOTSTRAP_PATH} \
    --with-isl=${BOOTSTRAP_PATH} \
    --with-headers=../../${NEWLIB}/newlib/libc/include \
    --enable-languages=c
make ${PARALLEL}
make install DESTDIR=${BUILD_TARGET_PATH}

popd

echo "# ==============================================================="
echo "# newlib (for ${BUILD} --> ${TARGET})"

pushd newlib*

rm -rf build-${BUILD_TARGET}
mkdir -p build-${BUILD_TARGET}
cd build-${BUILD_TARGET}
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
make install DESTDIR=${BUILD_TARGET_PATH}

popd

echo "# ==============================================================="
echo "# gcc (for ${BUILD} --> ${TARGET})"

pushd gcc*

rm -rf build-${BUILD_TARGET}-2
mkdir -p build-${BUILD_TARGET}-2
cd build-${BUILD_TARGET}-2
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
    --with-gmp=${BOOTSTRAP_PATH} \
    --with-mpfr=${BOOTSTRAP_PATH} \
    --with-mpc=${BOOTSTRAP_PATH} \
    --with-isl=${BOOTSTRAP_PATH} \
    --with-headers=../../${NEWLIB}/newlib/libc/include \
    --enable-languages=c,c++
make ${PARALLEL}
make install DESTDIR=${BUILD_TARGET_PATH}

popd

echo "# ==============================================================="
echo "# gdb (for ${BUILD} --> ${TARGET})"

pushd gdb*

rm -rf build-${BUILD_TARGET}
mkdir -p build-${BUILD_TARGET}
cd build-${BUILD_TARGET}
../configure --prefix=/gcc-toolchain \
    --target=${TARGET} \
    --disable-nls \
    --disable-werror \
    --disable-shared \
    --disable-libssp \
    --disable-libvtv \
    --enable-gold \
    --enable-lto \
    --enable-multilib \
    --enable-interwork \
    --enable-vtable-verify \
    --enable-expat \
    --with-expat=${BOOTSTRAP_PATH} \
    --with-newlib \
    --with-gmp=${BOOTSTRAP_PATH} \
    --with-mpfr=${BOOTSTRAP_PATH} \
    --with-mpc=${BOOTSTRAP_PATH} \
    --with-isl=${BOOTSTRAP_PATH}
make ${PARALLEL}
make install DESTDIR=${BUILD_TARGET_PATH}

popd

echo "# ==============================================================="
echo "# collect (for ${BUILD} --> ${TARGET})"

COLLECT=`pwd`/../artifacts/${GCC}_${BUILD_TARGET}_${SUFFIX}.tar.bz2

pushd ${BUILD_TARGET_PATH}
tar -jcvf ${COLLECT} gcc-toolchain
popd

done

popd
