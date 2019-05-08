#!/bin/bash

#
# Build navcoin-core package
#

# set version
VERSION='4.6.0'

# set number of cpu cores for make
CORES=3

echo
echo "Building navcoin-core $VERSION package"
echo



# configure
./configure CFLAGS="-O2 -mtune=cortex-a15.cortex-a7 -mfpu=neon" CXXFLAGS="-O2 -mtune=cortex-a15.cortex-a7 -mfpu=neon" --enable-hardening --without-gui
make -j${CORES}

# checkinstall to generate dpkg
checkinstall -D -y --maintainer "info@navcoin.org" --pkgname navcoin-core --pkgversion $VERSION --requires apache2,ntp --include=navdroid/navdroid_files


echo 
echo "Package built successfully"
echo
echo "Install using: dpkg -i <package_name>"
echo
