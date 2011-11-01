#!/bin/sh

BASE=`pwd`
MOUNTPOINT=/mnt
DEVICE=vnd0
SUDO=sudo

# Don't start without a imagefile as a parameter
if [ "$1" = "" ]; then
  echo "usage: $0 imagefile"
  exit 1
fi

IMAGEFILE=$1

echo "Cleanup if something failed the last time... (ignore any not currently mounted and Device not configured warnings)"
${SUDO} umount $MOUNTPOINT 
${SUDO} vnconfig -u $DEVICE

echo ""
echo "Mounting the imagefile as a device..."
${SUDO} vnconfig -c $DEVICE $IMAGEFILE

echo ""
echo "Mounting destination to ${MOUNTPOINT}..."
if ! ${SUDO} mount -o async /dev/${DEVICE}a ${MOUNTPOINT}; then
  echo Mount failed..
  exit
fi

echo Mount was successful, make any changes to $MOUNTPOINT and run \"umountimage.sh\" to unmount.
