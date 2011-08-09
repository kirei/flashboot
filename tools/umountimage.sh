#!/bin/sh
#
# $Id: umountimage.sh,v 1.1 2006/11/22 13:20:50 jakob Exp $

BASE=`pwd`
MOUNTPOINT=/mnt
DEVICE=svnd0
SUDO=sudo

echo "Umounting device and mountpoint..."
${SUDO} umount $MOUNTPOINT 
${SUDO} vnconfig -u $DEVICE

