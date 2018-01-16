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

pushd stage

BASE_PATH=`pwd`/${BUILD}/gcc-bootstrap/bin:$PATH
BASE_LD_LIBRARY_PATH=`pwd`/${BUILD}/gcc-bootstrap/lib:$LD_LIBRARY_PATH
BASE_LD_RUN_PATH=`pwd`/${BUILD}/gcc-bootstrap/lib:$LD_RUN_PATH

BOOTSTRAP_PATH=`pwd`/${BUILD}/gcc-bootstrap

echo "BOOTSTRAP_PATH=${BOOTSTRAP_PATH}"

# ==========================================================================
# cross builds

for TARGET in "$@"; do

BUILD_TARGET=${BUILD}_${TARGET}
BUILD_TARGET_BASE_PATH1=${GCC}_${TARGET}/${SUFFIX}
BUILD_TARGET_BASE_PATH=${BUILD}/${BUILD_TARGET_BASE_PATH1}
BUILD_TARGET_PATH=`pwd`/${BUILD_TARGET_BASE_PATH}

PATH=${BUILD_TARGET_PATH}/bin:${BASE_PATH};export PATH
LD_LIBRARY_PATH=${BUILD_TARGET_PATH}/lib:${BASE_LD_LIBRARY_PATH};export LD_LIBRARY_PATH
LD_RUN_PATH=${BUILD_TARGET_PATH}/lib:${BASE_LD_RUN_PATH};export LD_RUN_PATH

echo "# ==============================================================="
echo "# remove last toolchains (for ${BUILD} --> ${TARGET})"

rm -rf ${BUILD_TARGET_PATH}
mkdir -p ${BUILD_TARGET_PATH}

echo "# ==============================================================="
echo "# binutils (for ${BUILD} --> ${TARGET})"

pushd ${BINUTILS}

rm -rf build-${BUILD_TARGET}
mkdir -p build-${BUILD_TARGET}
cd build-${BUILD_TARGET}
../configure --prefix=${BUILD_TARGET_PATH} \
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
    --with-isl=${BOOTSTRAP_PATH} \
    --without-ppl \
    --without-cloog \
    CFLAGS="-O2 -fomit-frame-pointer -static -I${BOOTSTRAP_PATH}/include -I${BUILD_TARGET_PATH}/include" \
    CPPFLAGS="-fexceptions" \
    LDFLAGS=-"-static -L${BOOTSTRAP_PATH}/lib -L${BUILD_TARGET_PATH}/lib"
make ${PARALLEL}
make install
make ${PARALLEL} check

popd

echo "# ==============================================================="
echo "# gcc (${BUILD} --> ${TARGET})"

pushd ${GCC}

rm -rf build-${BUILD_TARGET}
mkdir -p build-${BUILD_TARGET}
cd build-${BUILD_TARGET}
../configure --prefix=${BUILD_TARGET_PATH} \
    --target=${TARGET} \
    --disable-nls \
    --disable-werror \
    --disable-shared \
    --disable-libssp \
    --disable-newlib-supplied-syscalls \
    --disable-decimal-float \
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
    --without-ppl \
    --without-cloog \
    --without-gnattools \
    --enable-languages=c,c++ \
    CFLAGS="-O2 -fomit-frame-pointer -static -I${BOOTSTRAP_PATH}/include -I${BUILD_TARGET_PATH}/include" \
    CPPFLAGS="-fexceptions" \
    LDFLAGS=-"-static -L${BOOTSTRAP_PATH}/lib -L${BUILD_TARGET_PATH}/lib"
make ${PARALLEL}
make install

popd

echo "# ==============================================================="
echo "# newlib (for ${BUILD} --> ${TARGET})"

pushd ${NEWLIB}

rm -rf build-${BUILD_TARGET}
mkdir -p build-${BUILD_TARGET}
cd build-${BUILD_TARGET}
../configure --prefix=${BUILD_TARGET_PATH} \
    --target=${TARGET} \
    --disable-nls \
    --disable-werror \
    --disable-shared \
    --disable-libssp \
    --disable-newlib-supplied-syscalls \
    --disable-decimal-float \
    --enable-newlib-io-long-long \
    --enable-newlib-register-fini \
    --enable-newlib-reent-small \
    --enable-newlib-multithread \
    --enable-newlib-nano-malloc \
    --enable-lite-exit \
    --enable-newlib-global-atexit \
    --enable-gold \
    --enable-lto \
    --enable-multilib \
    --enable-interwork \
    --enable-vtable-verify \
    --enable-languages=c,c++ \
    CFLAGS="-O2 -fomit-frame-pointer -static -I${BOOTSTRAP_PATH}/include -I${BUILD_TARGET_PATH}/include" \
    CPPFLAGS="-fexceptions" \
    LDFLAGS=-"-static -L${BOOTSTRAP_PATH}/lib -L${BUILD_TARGET_PATH}/lib"
make ${PARALLEL}
make install

popd

echo "# ==============================================================="
echo "# gdb (for ${BUILD} --> ${TARGET})"

pushd ${GDB}

rm -rf build-${BUILD_TARGET}
mkdir -p build-${BUILD_TARGET}
cd build-${BUILD_TARGET}
../configure --prefix=${BUILD_TARGET_PATH} \
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
    --with-expat=${BOOTSTRAP_PATH} \
    --with-newlib \
    --with-gmp=${BOOTSTRAP_PATH} \
    --with-mpfr=${BOOTSTRAP_PATH} \
    --with-mpc=${BOOTSTRAP_PATH} \
    --with-isl=${BOOTSTRAP_PATH} \
    CFLAGS="-O2 -fomit-frame-pointer -static -I${BOOTSTRAP_PATH}/include -I${BUILD_TARGET_PATH}/include" \
    CPPFLAGS="-fexceptions" \
    LDFLAGS=-"-static -L${BOOTSTRAP_PATH}/lib -L${BUILD_TARGET_PATH}/lib"
make ${PARALLEL}
make install

popd

echo "# ==============================================================="
echo "# collect (for ${BUILD} --> ${TARGET})"

COLLECT=`pwd`/../artifacts/${GCC}_${BUILD_TARGET}_${SUFFIX}.tar.bz2

pushd ${BUILD}
tar -jcvf ${COLLECT} ${BUILD_TARGET_BASE_PATH1}
popd

done

popd
