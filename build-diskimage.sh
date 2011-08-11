#!/bin/sh

BASE=`pwd`
SRCDIR=${BSDSRCDIR:-/usr/src}
DESTDIR=${DESTDIR:-${BASE}/sandbox}
KERNELFILE=${KERNELFILE:-${BASE}/obj/bsd.gz}
SUDO=sudo
DEVICE=svnd0
MOUNTPOINT=/mnt
TEMPFILE=/tmp/build-diskimage.tmp.$$

# This is for boot.conf and should match the kernel ttyspeed.
# Which should be 9600 for GENERIC-RD, 38400 for WRAP12 and 19200 for the rest.
TTYSPEED=${TTYSPEED:-19200}

# drive geometry information -- get the right one for your flash!!

# 128 MB cards
totalsize=250880       # "total sectors:"
bytessec=512           # "bytes/sector:"
sectorstrack=32        # "sectors/track:"
sectorscylinder=256    # "sectors/cylinder:"
trackscylinder=8       # "tracks/cylinder:"
cylinders=980          # "cylinders:"

# 256 MB cards
#totalsize=501760       # "total sectors:"
#bytessec=512           # "bytes/sector:"
#sectorstrack=32        # "sectors/track:"
#sectorscylinder=512    # "sectors/cylinder:"
#trackscylinder=16      # "tracks/cylinder:"
#cylinders=980          # "cylinders:"

# 489 MB cards
#totalsize=1001952      # "total sectors:"
#bytessec=512		# "bytes/sector:"
#sectorstrack=63	# "sectors/track:"
#sectorscylinder=1008  	# "sectors/cylinder:"
#trackscylinder=16      # "tracks/cylinder:"
#cylinders=994          # "cylinders:"


# Don't start without a imagefile as a parameter
if [ "$1" = "" ]; then
  echo "usage: $0 imagefile"
  exit 1	
fi

IMAGEFILE=$1

# Does the kernel exist at all
if [ ! -r $KERNELFILE ]; then
  echo "ERROR! $KERNELFILE does not exist or is not readable."
  exit 1
fi

echo "Cleanup if something failed the last time... (ignore any not currently mounted and Device not configured warnings)"
${SUDO} umount $MOUNTPOINT
${SUDO} vnconfig -u $DEVICE

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
${SUDO} fdisk -c $cylinders -h $trackscylinder -s $sectorstrack -f ${DESTDIR}/usr/mdec/mbr -e $DEVICE << __EOC >/dev/null
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
if ! ${SUDO} mount -o async /dev/${DEVICE}a ${MOUNTPOINT}; then
  echo Mount failed..
  exit
fi

echo ""
echo "Copying bsd kernel, boot blocks and /etc/boot.conf..."
${SUDO} cp ${DESTDIR}/usr/mdec/boot ${MOUNTPOINT}/boot
${SUDO} cp ${KERNELFILE} ${MOUNTPOINT}/bsd
${SUDO} mkdir ${MOUNTPOINT}/etc
${SUDO} sed "/^stty/s/19200/${TTYSPEED}/" < ${BASE}/initial-conf/boot.conf > ${MOUNTPOINT}/etc/boot.conf

echo ""
echo "Installing boot blocks..."
${SUDO} /usr/mdec/installboot ${MOUNTPOINT}/boot ${DESTDIR}/usr/mdec/biosboot ${DEVICE}

${SUDO} mkdir ${MOUNTPOINT}/conf
${SUDO} mkdir ${MOUNTPOINT}/pkg
# Here is where you add your own packages and configuration to the flash...

echo ""
echo "Unmounting and cleaning up..."
${SUDO} umount $MOUNTPOINT
${SUDO} vnconfig -u $DEVICE

echo ""
echo "And we are done..."
echo "Run \"mountimage.sh $IMAGEFILE\" to add configuration and packages."
echo "When you are done with the configuration, gzip the imagefile and move"
echo "it to the system with a flashwriter."
echo "Use \"gunzip -c image.gz | dd of=/dev/sd0c\" on unix to write to flash"
echo "On Windows you can use http://m0n0.ch/wall/physdiskwrite.php"
echo "Both these utilities allow the gzipped image to be used directly."
