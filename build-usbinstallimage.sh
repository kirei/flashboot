#!/bin/sh

# Update for each new release
SHORTREL="50"
LONGREL="5.0"

# Update ARC for the architecture to use
ARC=i386
#ARC=amd64

# Change if ftp.eu.openbsd.org is not the best place to get your files from
URLBASE="http://ftp.eu.openbsd.org/pub/OpenBSD/${LONGREL}"

# Another mirror
#URLBASE="http://ftp.netbsd.se/OpenBSD/${LONGREL}"


# No need to change anything below this line for new OS releases!
CWD=`pwd`
SUDO=sudo
DEVICE=vnd0
DEVICECD=vnd1
SOURCECD=install${SHORTREL}.iso
MOUNTPOINT=/mnt/image
MOUNTPOINTCD=/mnt/cd
TEMPFILE=/tmp/build-diskimage.tmp.$$
KERNELFILE=${KERNELFILE:-${MOUNTPOINTCD}/${LONGREL}/${ARC}/bsd.rd}
DISTSTUFF=diststuff

# drive geometry information

# 489 MB cards
totalsize=1001952	# "total sectors:"
bytessec=512		# "bytes/sector:"
sectorstrack=63		# "sectors/track:"
sectorscylinder=1008  	# "sectors/cylinder:"
trackscylinder=16	# "tracks/cylinder:"
cylinders=994		# "cylinders:"

# Don't start without a imagefile as a parameter
if [ "$1" = "" ]; then
  echo "usage: $0 imagefile"
  exit 1
fi

IMAGEFILE=$1

# Make directory for dist stuff
mkdir -p ${DISTSTUFF}/${ARC}


echo ""
echo "Downloading SHA256..."
if [ ! -f ${DISTSTUFF}/${ARC}/SHA256 ] ; then
        echo "Needed SHA256, didn't find it in current dir so downloading..."
        ftp -o ${DISTSTUFF}/${ARC}/SHA256 ${URLBASE}/${ARC}/SHA256
else
        echo "SHA256 already exist, don't need to download it again"
fi

echo ""
echo "Downloading ${SOURCECD}..."
if [ ! -f ${DISTSTUFF}/${ARC}/${SOURCECD} ] ; then
	echo "Needed ${SOURCECD}, didn't find it in current dir so downloading..."
	ftp -o ${DISTSTUFF}/${ARC}/${SOURCECD} ${URLBASE}/${ARC}/${SOURCECD}
else
	echo "${SOURCECD} already exist, don't need to download it again"
fi

echo ""
echo "Calculating sha256 checksum of ${SOURCECD} to verify against SHA256 file..."
cd ${DISTSTUFF}/${ARC} 
if [ "$(cat "SHA256" | grep "${SOURCECD}")" = "$(sha256 "${SOURCECD}")" ]; then
        echo "checksum match!"
else
        echo "sha256 sum of ${SOURCECD} does not match, please verifiy!"
        exit 1
fi
cd ${CWD}
echo ""
echo "Cleanup if something failed the last time... (ignore any not currently mounted and Device not configured warnings)"
${SUDO} umount $MOUNTPOINT
${SUDO} vnconfig -u $DEVICE
${SUDO} umount $MOUNTPOINTCD
${SUDO} vnconfig -u $DEVICECD

echo ""
echo "Creating an image file, if one doesn't exist..."
if [ ! -f $IMAGEFILE ] ; then
  dd if=/dev/zero of=$IMAGEFILE bs=$bytessec count=$totalsize
fi

echo ""
echo "Mounting the imagefile as a device..."
${SUDO} vnconfig -c $DEVICE $IMAGEFILE

echo ""
echo "Running fdisk... (Ignore any sysctl(machdep.bios.diskinfo): Device not configured warnings)"
${SUDO} fdisk -c $cylinders -h $trackscylinder -s $sectorstrack -f /usr/mdec/mbr -e $DEVICE << __EOC >/dev/null
reinit
update
write
quit
__EOC

let asize=$totalsize-$sectorstrack

echo "type: SCSI" >> $TEMPFILE
echo "disk: vnd device" >> $TEMPFILE
echo "label: fictitious" >> $TEMPFILE
echo "flags:" >> $TEMPFILE
echo "bytes/sector: ${bytessec}" >> $TEMPFILE
echo "sectors/track: ${sectorstrack}" >> $TEMPFILE
echo "tracks/cylinder: ${trackscylinder}" >> $TEMPFILE
echo "sectors/cylinder: ${sectorscylinder}" >> $TEMPFILE
echo "cylinders: ${cylinders}" >> $TEMPFILE
echo "total sectors: ${totalsize}" >> $TEMPFILE
echo "rpm: 3600" >> $TEMPFILE
echo "interleave: 1" >> $TEMPFILE
echo "trackskew: 0" >> $TEMPFILE
echo "cylinderskew: 0" >> $TEMPFILE
echo "headswitch: 0           " >> $TEMPFILE
echo "track-to-track seek: 0  " >> $TEMPFILE
echo "drivedata: 0 " >> $TEMPFILE
echo "" >> $TEMPFILE
echo "16 partitions:" >> $TEMPFILE
echo "a:	$asize	$sectorstrack	4.2BSD	2048	16384	16" >> $TEMPFILE
echo "c:	$totalsize	0	unused	0	0" >> $TEMPFILE

echo ""
echo "Installing disklabel..."
${SUDO} disklabel -R $DEVICE $TEMPFILE
rm $TEMPFILE

echo ""
echo "Creating new filesystem..."
${SUDO} newfs -q /dev/r${DEVICE}a

echo ""
echo "Mounting destination to ${MOUNTPOINT}..."
if [ -d ${MOUNTPOINT} ]; then
	${SUDO} rm -r ${MOUNTPOINT}
fi
${SUDO} mkdir -p ${MOUNTPOINT}
if ! ${SUDO} mount -o async /dev/${DEVICE}a ${MOUNTPOINT}; then
	echo Mount failed..
	exit
fi

echo ""
echo "Mounting the install iso as a device..."
${SUDO} vnconfig $DEVICECD ${DISTSTUFF}/${ARC}/${SOURCECD}

echo ""
echo "Mouting install cd to ${MOUNTPOINTCD}..."
if [ -d ${MOUNTPOINTCD} ]; then
	${SUDO} rm -r ${MOUNTPOINTCD}
fi
${SUDO} mkdir -p ${MOUNTPOINTCD}
if ! ${SUDO} mount -t cd9660 /dev/${DEVICECD}c ${MOUNTPOINTCD}; then
	echo Mount failed..
	exit
fi

echo ""
echo "Copying bsd kernel and boot blocks..."
${SUDO} cp /usr/mdec/boot ${MOUNTPOINT}/boot
${SUDO} cp ${KERNELFILE} ${MOUNTPOINT}/bsd

echo ""
echo "Installing boot blocks..."
${SUDO} /usr/mdec/installboot ${MOUNTPOINT}/boot /usr/mdec/biosboot ${DEVICE}

echo ""
echo "Copying files"
${SUDO} cp -R ${MOUNTPOINTCD}/* ${MOUNTPOINT}

echo ""
echo "Unmounting and cleaning up..."
${SUDO} umount $MOUNTPOINT
${SUDO} vnconfig -u $DEVICE
${SUDO} umount $MOUNTPOINTCD
${SUDO} vnconfig -u $DEVICECD
${SUDO} rm -r ${MOUNTPOINT}
${SUDO} rm -r ${MOUNTPOINTCD}

echo ""
echo "gzipping ${IMAGEFILE} to ${IMAGEFILE}.gz..."
gzip ${IMAGEFILE}

echo ""
echo "And we are done..."
echo "Use \"gunzip -c ${IMAGEFILE}.gz | dd of=/dev/sd0c\" on unix to write to flash"
echo "On Windows you can use http://m0n0.ch/wall/physdiskwrite.php"
echo "Both these utilities allow the gzipped image to be used directly."
