#!/bin/bash

# (c) Copyright 2018 Ribose Inc.
#

# Based on:
# https://github.com/riboseinc/ruby-rnp/blob/52d6113458cb095cf7811/ci/install.sh

set -eux

: "${CORES:=2}"
: "${MAKE:=make}"

botan_build="${DEPS_BUILD_DIR}/botan"

if [ ! -e "${BOTAN_PREFIX}/lib/libbotan-2.so" ] && \
	 [ ! -e "${BOTAN_PREFIX}/lib/libbotan-2.dylib" ]; then

	if [ -d "${botan_build}" ]; then
		rm -rf "${botan_build}"
	fi

	git clone --depth 1 --branch "2.18.1" https://github.com/randombit/botan "${botan_build}"
	pushd "${botan_build}"
	./configure.py --prefix="${BOTAN_PREFIX}" --with-debug-info --cxxflags="-fno-omit-frame-pointer"
	${MAKE} -j${CORES} install
	popd
fi
