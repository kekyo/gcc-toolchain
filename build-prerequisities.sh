#!/bin/bash

set -e

BUILD=${BUILD:-`gcc -dumpmachine`}
TARGET=${TARGET:-arm-none-eabi}

AUTOCONF=${AUTOCONF:-autoconf-2.64}
ICONV=${ICONV:-libiconv-1.15}
NEWLIB=${NEWLIB:-newlib-2.5.0}
BINUTILS=${BINUTILS:-binutils-2.29.1}
GCC=${GCC:-gcc-7.2.0}
GDB=${GDB:-gdb-8.0.1}
EXPAT_VERSION=${EXPAT:-2.2.5}
EXPAT=${EXPAT:-expat-${EXPAT_VERSION}}

NPROC=${NPROC:-$((`nproc`*2))}
PARALLEL=${PARALLEL:--j${NPROC}}

echo "# ==============================================================="
echo "# download"

mkdir -p artifacts
pushd artifacts

if [ ! -f ${AUTOCONF}.tar.bz2 ] ; then
    wget http://ftpmirror.gnu.org/autoconf/${AUTOCONF}.tar.bz2
fi
if [ ! -f ${ICONV}.tar.gz ] ; then
    wget http://ftpmirror.gnu.org/libiconv/${ICONV}.tar.gz
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

popd

echo "# ==============================================================="
echo "# extract"

mkdir -p stage
pushd stage

if [ ! -d ${AUTOCONF} ] ; then
    echo "Extracting: ${AUTOCONF}"
    tar -jxf ../artifacts/${AUTOCONF}.tar.bz2
fi
if [ ! -d ${ICONV} ] ; then
    echo "Extracting: ${ICONV}"
    tar -zxf ../artifacts/${ICONV}.tar.gz
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

popd

echo "# ==============================================================="
echo "# download and extract by gcc's prerequisities"

pushd stage

cd ${GCC}
contrib/download_prerequisites --directory=..
cd ..

rm *.bz2
rm *.gz

popd

echo "# ==============================================================="
echo "# remove last bootstraps"

pushd stage

BOOTSTRAP_PATH=`pwd`/${BUILD}/gcc-bootstrap
rm -rf ${BOOTSTRAP_PATH}

popd

# ==========================================================================
# bootstrap builds

pushd stage

echo "# ==============================================================="
echo "# autoconf"

pushd ${AUTOCONF}

rm -rf build
mkdir -p build
cd build
../configure --prefix=${BOOTSTRAP_PATH}
make ${PARALLEL}
make install
# Autoconf's test too long
#make ${PARALLEL} check

popd

pushd ${BINUTILS}

# binutils contains unstable configure script, so we have to regenerate by autoconf.
${BOOTSTRAP_PATH}/bin/autoconf

popd

echo "# ==============================================================="
echo "# libiconv (bootstrap)"

pushd libiconv*

rm -rf build-bootstrap
mkdir -p build-bootstrap
cd build-bootstrap
../configure --prefix=${BOOTSTRAP_PATH} \
    --disable-shared \
    --disable-rpath \
    --disable-nls \
    --enable-relocatable \
    CFLAGS="-O2 -fomit-frame-pointer -static -I${BOOTSTRAP_PATH}/include" \
    CPPFLAGS="-fexceptions" \
    LDFLAGS=-"-static -L${BOOTSTRAP_PATH}/lib"
make ${PARALLEL}
make install

popd

echo "# ==============================================================="
echo "# gmp (bootstrap)"

pushd gmp*

rm -rf build-bootstrap
mkdir -p build-bootstrap
cd build-bootstrap
../configure --prefix=${BOOTSTRAP_PATH} \
    --disable-shared \
    CFLAGS="-O2 -fomit-frame-pointer -static -I${BOOTSTRAP_PATH}/include" \
    CPPFLAGS="-fexceptions" \
    LDFLAGS=-"-static -L${BOOTSTRAP_PATH}/lib"
make ${PARALLEL}
make install
make ${PARALLEL} check

popd

echo "# ==============================================================="
echo "# mpfr (bootstrap)"

pushd mpfr*

rm -rf build-bootstrap
mkdir -p build-bootstrap
cd build-bootstrap
../configure --prefix=${BOOTSTRAP_PATH} \
    --disable-shared \
    --with-gmp=${BOOTSTRAP_PATH} \
    CFLAGS="-O2 -fomit-frame-pointer -static -I${BOOTSTRAP_PATH}/include" \
    CPPFLAGS="-fexceptions" \
    LDFLAGS=-"-static -L${BOOTSTRAP_PATH}/lib"
make ${PARALLEL}
make install
make ${PARALLEL} check

popd

echo "# ==============================================================="
echo "# mpc (bootstrap)"

pushd mpc*

rm -rf build-bootstrap
mkdir -p build-bootstrap
cd build-bootstrap
../configure --prefix=${BOOTSTRAP_PATH} \
    --disable-shared \
    --with-gmp=${BOOTSTRAP_PATH} \
    --with-mpfr=${BOOTSTRAP_PATH} \
    CFLAGS="-O2 -fomit-frame-pointer -static -I${BOOTSTRAP_PATH}/include" \
    CPPFLAGS="-fexceptions" \
    LDFLAGS=-"-static -L${BOOTSTRAP_PATH}/lib"
make ${PARALLEL}
make install
make ${PARALLEL} check

popd

echo "# ==============================================================="
echo "# isl (bootstrap)"

pushd isl*

rm -rf build-bootstrap
mkdir -p build-bootstrap
cd build-bootstrap
../configure --prefix=${BOOTSTRAP_PATH} \
    --disable-shared \
    --with-gmp-prefix=${BOOTSTRAP_PATH} \
    CFLAGS="-O2 -fomit-frame-pointer -static -I${BOOTSTRAP_PATH}/include" \
    CPPFLAGS="-fexceptions" \
    LDFLAGS=-"-static -L${BOOTSTRAP_PATH}/lib"
make ${PARALLEL}
make install
make ${PARALLEL} check

popd

echo "# ==============================================================="
echo "# expat (bootstrap)"

pushd expat*

rm -rf build-bootstrap
mkdir -p build-bootstrap
cd build-bootstrap
../configure --prefix=${BOOTSTRAP_PATH} \
    --disable-shared \
    CFLAGS="-O2 -fomit-frame-pointer -static -I${BOOTSTRAP_PATH}/include" \
    CPPFLAGS="-fexceptions" \
    LDFLAGS=-"-static -L${BOOTSTRAP_PATH}/lib"
make ${PARALLEL}
make install

popd

popd
