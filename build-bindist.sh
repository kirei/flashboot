#!/bin/sh

# Functions
function getrandomduid {
        # Generates a 16 chars long hex string
        tempduid=`cat /dev/urandom | tr -dc "a-f0-9" | fold -w 16 | head -1`
        echo ${tempduid}
}

DUID=`getrandomduid`

export DUID

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

DISTNAME=PENDRIVE
./build-usbkernel.sh GENERIC-RD ${DUID}
./build-usbimage.sh pendrive ${DUID}
gzip pendrive
mv pendrive.gz bindist/${DISTNAME}.image

DISTNAME=LIVECD
sh ./build-livecd.sh GENERIC-RD
mv obj/live_cd*.iso bindist/
echo "All images, iso and kernels has been moved to bindist"
