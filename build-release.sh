#!/bin/sh
#
# $Id: build-release.sh,v 1.3 2007/09/19 05:13:31 jakob Exp $

set -xe

BASE=`pwd`

BSDSRCDIR=${BSDSRCDIR:-/usr/src}
BSDOBJDIR=${BSDOBJDIR:-${BASE}/flash-obj}
DESTDIR=${DESTDIR:-${BASE}/flash-dist}

_MINI=-mini

RELEASEDIR=${BASE}/release${_MINI}
MAKECONF=${BASE}/mk${_MINI}.conf
SUDO="sudo MAKECONF=${MAKECONF}"

export BSDSRCDIR BSDOBJDIR DESTDIR RELEASEDIR MAKECONF SUDO

cd ${BSDSRCDIR}
mkdir -p ${BSDOBJDIR} ${DESTDIR}

if [ "x$1" != "xbuilt" ] ; then
	${SUDO} rm -rf ${DESTDIR}/*
	${SUDO} make -k cleandir
	rm -rf ${BSDOBJDIR}/*
	
	make obj
	cd etc
	make distrib-dirs
	cd ..
	
	make build
fi

cd etc
${SUDO} make distribution-etc-root-var
cd ..
