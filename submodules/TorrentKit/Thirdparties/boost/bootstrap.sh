#!/bin/bash

BOOST_TARBALL="boost.tar.gz"

DIR=`pwd` 
SRC_DIR="${DIR}/src"
BUILD_DIR="${DIR}/build"

clean() {
	rm ${BOOST_TARBALL}
	rm -rf ${SRC_DIR}
	rm -rf ${BUILD_DIR}
}

download() {
	curl -L -o ${BOOST_TARBALL} \
		"https://boostorg.jfrog.io/artifactory/main/release/1.69.0/source/boost_1_69_0.tar.gz"
}

extract() {
	rm -rf ${SRC_DIR} && mkdir ${SRC_DIR}
	tar -xzf ${BOOST_TARBALL} --strip 1 -C ${SRC_DIR}
}

clean
download
extract

echo "Done."