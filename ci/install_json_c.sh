#!/bin/bash

# (c) Copyright 2018 Ribose Inc.
#

# Based on:
# https://github.com/riboseinc/ruby-rnp/blob/52d6113458cb095cf7811/ci/install.sh

set -eux

: "${CORES:=2}"
: "${MAKE:=make}"

jsonc_build="${DEPS_BUILD_DIR}/json-c"

if [ ! -e "${JSONC_PREFIX}/lib/libjson-c.so" ] && \
	 [ ! -e "${JSONC_PREFIX}/lib/libjson-c.dylib" ]; then

	 if [ -d "${jsonc_build}" ]; then
		 rm -rf "${jsonc_build}"
	 fi

	mkdir -p "${jsonc_build}"
	pushd ${jsonc_build}
	wget https://s3.amazonaws.com/json-c_releases/releases/json-c-0.12.1.tar.gz -O json-c.tar.gz
	tar xzf json-c.tar.gz --strip 1

	autoreconf -ivf
	env CFLAGS="-fno-omit-frame-pointer -g -Wno-implicit-fallthrough" ./configure --prefix="${JSONC_PREFIX}"
	${MAKE} -j${CORES} install
	popd
fi
