#!/bin/bash

# (c) Copyright 2018 Ribose Inc.
#

# Based on:
# https://github.com/riboseinc/ruby-rnp/blob/52d6113458cb095cf7811/ci/install.sh

set -eux

: "${CORES:=2}"
: "${MAKE:=make}"

rnp_build="${DEPS_BUILD_DIR}/rnp"

if [ ! -e "${RNP_PREFIX}/lib/librnp.so" ] && \
	 [ ! -e "${RNP_PREFIX}/lib/librnp.dylib" ]; then

	git clone https://github.com/riboseinc/rnp ${rnp_build}
	pushd "${rnp_build}"
	git checkout "$RNP_VERSION"
	cmake \
		-DCMAKE_BUILD_TYPE=RelWithDebInfo \
		-DBUILD_SHARED_LIBS=yes \
		-DBUILD_TESTING=no \
		-DCMAKE_PREFIX_PATH="${BOTAN_PREFIX};${JSONC_PREFIX}" \
		-DCMAKE_INSTALL_PREFIX="${RNP_PREFIX}" \
		.
	${MAKE} -j${CORES} install
	popd
fi
