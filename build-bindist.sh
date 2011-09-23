#!/bin/sh

mkdir bindist

DISTNAME=WRAP12
export TTYSPEED=38400
./build-kernel.sh ${DISTNAME}
cp obj/bsd.gz bindist/${DISTNAME}.bsd
./build-diskimage.sh image
gzip image
mv image.gz bindist/${DISTNAME}.image

DISTNAME=PCENGINES
export TTYSPEED=38400
./build-kernel.sh ${DISTNAME}
cp obj/bsd.gz bindist/${DISTNAME}.bsd
./build-diskimage.sh image
gzip image
mv image.gz bindist/${DISTNAME}.image

DISTNAME=COMMELL-LE564
export TTYSPEED=19200
./build-kernel.sh ${DISTNAME}
cp obj/bsd.gz bindist/${DISTNAME}.bsd
./build-diskimage.sh image
gzip image
mv image.gz bindist/${DISTNAME}.image

DISTNAME=GENERIC-RD
export TTYSPEED=9600
./build-kernel.sh ${DISTNAME}
cp obj/bsd.gz bindist/${DISTNAME}.bsd
./build-diskimage.sh image
gzip image
mv image.gz bindist/${DISTNAME}.image

DISTNAME=SOEKRIS4501
export TTYSPEED=19200
./build-kernel.sh ${DISTNAME}
cp obj/bsd.gz bindist/${DISTNAME}.bsd
./build-diskimage.sh image
gzip image
mv image.gz bindist/${DISTNAME}.image

DISTNAME=SOEKRIS4521
export TTYSPEED=19200
./build-kernel.sh ${DISTNAME}
cp obj/bsd.gz bindist/${DISTNAME}.bsd
./build-diskimage.sh image
gzip image
mv image.gz bindist/${DISTNAME}.image

DISTNAME=SOEKRIS4801
export TTYSPEED=19200
./build-kernel.sh ${DISTNAME}
cp obj/bsd.gz bindist/${DISTNAME}.bsd
./build-diskimage.sh image
gzip image
mv image.gz bindist/${DISTNAME}.image

DISTNAME=SOEKRIS5501
export TTYSPEED=19200
./build-kernel.sh ${DISTNAME}
cp obj/bsd.gz bindist/${DISTNAME}.bsd
./build-diskimage.sh image
gzip image
mv image.gz bindist/${DISTNAME}.image

DISTNAME=LIVECD
sh ./build-livecd.sh GENERIC-RD
mv obj/live_cd*.iso bindist/
