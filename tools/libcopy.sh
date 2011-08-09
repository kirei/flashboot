#!/bin/sh

SOURCEROOT=$1
TARGET=$2
shift; shift

LIBS=`ldd $* 2>/dev/null | grep '[0-9a-fA-F] rlib ' | cut -d/ -f2- | sort -u`

for ll in $LIBS ; do 
	lfn=`basename ${ll}`
	[ -f "${TARGET}/${lfn}" ] && continue
	echo "${SOURCEROOT}/${ll} => ${TARGET}/${lfn}"
	cp -p ${SOURCEROOT}/${ll} ${TARGET}/${lfn}
done

