#!/bin/bash

#
# Build navcoin-core package
#
# Do not run this script from /tmp unless you are root because
# the package is written to the parent of the current directory
#

# set version
VERSION='4.6.0'

# set number of cpu cores for make
CORES=3

echo
echo "Building navcoin-core $VERSION package"
echo

DIR=`pwd`
PARENTDIR="$(dirname "$dir")"

# configure
./configure CFLAGS="-O2 -mtune=cortex-a15.cortex-a7 -mfpu=neon" CXXFLAGS="-O2 -mtune=cortex-a15.cortex-a7 -mfpu=neon" --enable-hardening --without-gui
make -j${CORES}

# checkinstall to generate dpkg
checkinstall -D -y --maintainer "info@navcoin.org" --pkgname navcoin-core --pkgversion $VERSION --requires ntp --include=navdroid/navdroid_files --install=no --backup=no --pakdir=$PARENTDIR


echo 
echo "Package built successfully and written to $PARENTDIR"
echo
echo "Install using: dpkg -i <package_name>"
echo
