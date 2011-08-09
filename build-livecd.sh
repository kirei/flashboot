#!/bin/ksh
#
# Builds a 20MB kernel to boot from cd and creates iso image 

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

# Modify list.temp to use fstab.initial.iso and
# add mount_cd9660.
cat list.temp | sed 's/fstab.initial/fstab.initial.iso/' |  sed '/mount_msdos/a\
COPY	${DESTDIR}/sbin/mount_cd9660		sbin/mount_cd9660\
' > list.temp

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
make KCONF=${KERNEL} LIST=${BASE}/list.temp NBLKS=${NBLKS} \
DISKPROTO=${BASE}/disktabs/${DISKTAB} $2 $3 $4

# Cleanup
rm -f list.temp
rm -f $KERNEL

# Done
echo "Your kernel is stored here ${BASE}/obj/"

# Prepare directory for creating cd image

mkdir -p live_cd/etc
cp flash-dist/usr/mdec/cdbr live_cd/cdbr
cp flash-dist/usr/mdec/cdboot live_cd/cdboot
cp initial-conf/boot.conf.iso live_cd/etc/boot.conf
cp obj/bsd.gz live_cd/bsd

# Create the image

vers=`uname -r`
#/usr/local/bin/mkisofs -no-iso-translate \
#-R -T -allow-leading-dots -l -d -D -N -v \
#-V "LiveCD flashboot-${vers}" -A "LiveCD flashboot-${vers}" \
#-b cdboot -no-emul-boot -c boot.catalog \
#-o ./obj/live_cd-${vers}.iso ./live_cd
/usr/sbin/mkhybrid -R -T -l -L -d -D -N -v \
-V "LiveCD flashboot-${vers}" \
-A "LiveCD flashboot-${vers}" \
-b cdbr \
-c boot.catalog \
-o ./obj/live_cd-${vers}.iso \
./live_cd/

echo "Your iso image is here ${BASE}/obj/live_cd-${vers}.iso"
