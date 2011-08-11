#!/bin/sh

CWD=`pwd`
WORKDIR=sandbox

if ! [ -d ${CWD}/${WORKDIR}/dev  ]; then
  echo "You have no sandbox to play with yet. Run sudo ./build-release.sh first"
  exit
fi

echo "Setting up environment.."

mount_mfs -o nosuid -s 32768 swap ${CWD}/${WORKDIR}/dev
cp -p ${CWD}/${WORKDIR}/dev-orig/MAKEDEV ${CWD}/${WORKDIR}/dev/MAKEDEV
cd ${CWD}/${WORKDIR}/dev
./MAKEDEV std
echo "Going into chroot to take a look.."
/usr/sbin/chroot ${CWD}/${WORKDIR} /bin/ksh 

sleep 3
cd
rm -rf ${CWD}/${WORKDIR}/dev/*
umount ${CWD}/${WORKDIR}/dev

echo "We are no longer in chroot!"

exit

