#!/bin/sh

# Check DUID format (hex and 16 char long string)
if [[ "$DUID" != +([[:xdigit:]]) ]] || [[ ${#DUID} != 16 ]]; then
  echo "DUID: ${DUID} is not a 16-character hexadecimal string"
  exit
fi;

# Create dir if not there
mkdir -p obj

# Create a templist
cat list > list.temp
# Include custom list if exist
if [ -r list.custom ]; then
      cat list.custom >> list.temp
fi

# Modify list.temp to use fstab.initial.usb and
# add mount_cd9660.
cat list.temp | sed 's/fstab.initial/fstab.initial.usb/' |  sed '/mount_msdos/a\
COPY	${DESTDIR}/sbin/mount_cd9660		sbin/mount_cd9660\
' > list.temp2
rm list.temp
mv list.temp2 list.temp

# Modify fstab.initial.usb and replace predefined UID with the defined one
sed 's/0123456789abcdef/'"${1}"'/g' initial-conf/fstab.initial.usb > initial-conf/fstab.initial.usb.tmp
rm initial-conf/fstab.initial.usb
mv initial-conf/fstab.initial.usb.tmp initial-conf/fstab.initial.usb

# Cleanup just in case the previous build failed
umount /mnt
vnconfig -u vnd0
make KCONF=${KERNEL} clean

# Make kernel
make termdefs bsd KCONF=${KERNEL} LIST=/list.temp NBLKS=${NBLKS} DISKPROTO=/disktabs/${DISKTAB}

exit

