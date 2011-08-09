#!/bin/sh
#
# Builds a 20MB kernel

BASE=`pwd`
SRCDIR=${BSDSRCDIR:-/usr/src}
DESTDIR=${DESTDIR:-${BASE}/flash-dist}
SUDO=sudo

DISKTAB=disktab.20mb
NBLKS=40960

export SRCDIR DESTDIR SUDO

# Don't start without a kernel as a parameter
if [ "$1" = "" ]; then
  echo "usage: $0 kernel"
  exit 1
fi

# Does the kernel exist at all
if [ ! -r $1 ]; then
  echo "ERROR! $1 does not exist or is not readable."
  exit 1
fi

# Create dir if not there
mkdir -p obj

# Create a templist 
cat list list.largekernel > list.temp

# Which kernel to use?
export KERNEL=$1.LARGE

# Create the kernelfile (with increased MINIROOTSIZE)
grep -v MINIROOTSIZE $1 > $KERNEL
echo "option MINIROOTSIZE=${NBLKS}" >> $KERNEL

# Cleanup just in case the previous build failed
${SUDO} umount /mnt/ 
${SUDO} vnconfig -u vnd0
make KCONF=${KERNEL} clean

# Make kernel
make KCONF=${KERNEL} LIST=${BASE}/list.temp NBLKS=${NBLKS} DISKPROTO=${BASE}/disktabs/${DISKTAB} $2 $3 $4

# Cleanup
rm -f list.temp
rm -f $KERNEL

# Done
echo "Your kernel is stored here ${BASE}/obj/"
