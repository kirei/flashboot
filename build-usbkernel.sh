#!/bin/sh
#
# Builds a 48MB kernel to put on a USB-stick

# Functions
function getrandomduid {
	# Generates a 16 chars long hex string
        tempduid=`cat /dev/urandom | tr -dc "a-f0-9" | fold -w 16 | head -1`
        echo ${tempduid}
}

CWD=`pwd`
WORKDIR=sandbox
DISKTAB=disktab.48mb
NBLKS=98304
SRCDIR=${BSDSRCDIR:-/usr/src}
DESTDIR=${DESTDIR:-${CWD}/${WORKDIR}}
DUID=${2:-`getrandomduid`}
export SRCDIR DESTDIR CWD WORKDIR DISKTAB NBLKS DUID

# Don't start without a kernel as a parameter
if [ "$1" = "" ]; then
  echo "usage: $0 kernel [duid]"
  echo
  echo "The options are as follows:"
  echo "[duid]:		Optional 16-character hexadecimal string used as"
  echo "		disklabel UID for the storage device mounted as /flash"
  echo "		If unset a random number is generated and printed at" 
  echo "		the end of the script"
  exit 1
fi

# Does the kernel exist at all
if [ ! -r $1 ]; then
  echo "ERROR! $1 does not exist or is not readable."
  exit 1
fi

# Quick test to see if sandbox exist
if ! [ -d ${CWD}/${WORKDIR}/dev  ]; then
  echo "You must build your release first. Run sudo ./build-release.sh"
  exit
fi

# Check DUID format (hex and 16 char long string)
if [[ "$DUID" != +([[:xdigit:]]) ]] || [[ ${#DUID} != 16 ]]; then
  echo "DUID: ${DUID} is not a 16-character hexadecimal string"
  exit
fi;

# Which kernel to use?
export KERNEL=$1

# Create the kernelfile (with increased MINIROOTSIZE)
grep -v MINIROOTSIZE $1 > ${CWD}/${WORKDIR}/${KERNEL}
echo "option MINIROOTSIZE=${NBLKS}" >> ${CWD}/${WORKDIR}/${KERNEL}

echo "Setting up environment.."

umount ${CWD}/${WORKDIR}/dev
mount_mfs -o nosuid -s 32768 swap ${CWD}/${WORKDIR}/dev
cp -p ${CWD}/${WORKDIR}/dev-orig/MAKEDEV ${CWD}/${WORKDIR}/dev/MAKEDEV
cd ${CWD}/${WORKDIR}/dev
./MAKEDEV all
cp -p ${CWD}/$1 ${CWD}/${WORKDIR}/
cp -p ${CWD}/Makefile ${CWD}/${WORKDIR}/
cp -p ${CWD}/build-usbkernel-injail.sh ${CWD}/${WORKDIR}/
cp -p ${CWD}/list ${CWD}/${WORKDIR}/
cp -p ${CWD}/list.recovery ${CWD}/${WORKDIR}/
# Include custom list if exist
if [ -r ${CWD}/list.custom ]; then
	cp -p ${CWD}/list.custom ${CWD}/${WORKDIR}/
fi
cp -p ${CWD}/conf ${CWD}/${WORKDIR}/
cp -p ${CWD}/mtree.conf ${CWD}/${WORKDIR}/
cp -pR ${CWD}/disktabs ${CWD}/${WORKDIR}/
cp -pR ${CWD}/tools ${CWD}/${WORKDIR}/
cp -pR ${CWD}/initial-conf ${CWD}/${WORKDIR}/
rm -r ${CWD}/${WORKDIR}/obj
mkdir -p ${CWD}/${WORKDIR}/obj
mkdir -p ${CWD}/obj

# Don't want anything mounted to /mnt when we starts
umount /mnt

echo "Going into chroot to build kernel"
/usr/sbin/chroot ${CWD}/${WORKDIR} ./build-usbkernel-injail.sh ${DUID}

echo "Comming back from chroot"

# Clean up /dev for the creation of file system
rm -rf ${CWD}/${WORKDIR}/dev/*
cd ${CWD}/${WORKDIR}
umount ${CWD}/${WORKDIR}/dev
cp -p ${CWD}/${WORKDIR}/dev-orig/MAKEDEV ${CWD}/${WORKDIR}/dev/MAKEDEV

echo "Building file system"
cd ${CWD}/${WORKDIR}/

# From Makefile that could not run in a chroot
make mr.fs rdsetroot KCONF=${KERNEL} LIST=${CWD}/${WORKDIR}/list.temp NBLKS=${NBLKS} DISKPROTO=${CWD}/${WORKDIR}/disktabs/${DISKTAB}
cp ${CWD}/${WORKDIR}/obj/bsd ${CWD}/${WORKDIR}/obj/bsd.rd
${CWD}/${WORKDIR}/obj/rdsetroot ${CWD}/${WORKDIR}/obj/bsd.rd < ${CWD}/${WORKDIR}/obj/mr.fs
gzip -c9 ${CWD}/${WORKDIR}/obj/bsd.rd > ${CWD}/${WORKDIR}/obj/bsd.gz

# Clean up
rm -rf ${CWD}/${WORKDIR}/dev/*
rm -r ${CWD}/obj/*
rm -f list.temp
rm -f $KERNEL

# Move kernel files from sandbox to the "old" location as before chroot
mv ${CWD}/${WORKDIR}/obj/* ${CWD}/obj/

# Done
echo "Your kernel is stored here ${CWD}/obj/"
echo "The UID that are used in the ramdisk kernel is ${DUID}"
echo "You *MUST* pass this UID to build-usbimage.sh as the second parameter"
echo "or the image will fail to mount /flash."
