#!/bin/sh
#
# $Id: wantlibcopy.sh,v 1.2 2009/11/02 22:24:13 jakob Exp $

SOURCEROOT=$1
TARGET=$2
shift; shift

for x in $* ; do 
  LIBS=`ldd ${SOURCEROOT}/usr/lib/lib${x}.so.* 2>/dev/null | grep '[0-9a-fA-F] dlib ' | cut -d/ -f2- | sort -u`
  for ll in $LIBS ; do 
	lfn=`basename ${ll}`
	[ -f "${TARGET}/${lfn}" ] && continue
	echo "/${ll} => ${TARGET}/${lfn}"
	cp -p /${ll} ${TARGET}/${lfn}
  done
done

