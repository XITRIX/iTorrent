#!/bin/bash

LIBTORRENT_TARBALL="libtorrent.tar.gz"

DIR=`pwd` 
SRC_DIR="${DIR}/src"
BUILD_DIR="${DIR}/build"

clean() {
	rm ${LIBTORRENT_TARBALL}
	rm -rf ${SRC_DIR}
	rm -rf ${BUILD_DIR}
}

download() {
	curl -L -o ${LIBTORRENT_TARBALL} \
		"https://github.com/arvidn/libtorrent/releases/download/v1.2.14/libtorrent-rasterbar-1.2.14.tar.gz"
}

extract() {
	rm -rf ${SRC_DIR} && mkdir ${SRC_DIR}
	tar -xzf ${LIBTORRENT_TARBALL} --strip 1 -C ${SRC_DIR}
}

clean
download
extract

echo "Done."