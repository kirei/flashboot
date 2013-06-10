#!/bin/sh

CWD=`pwd`
WORKDIR=sandbox

export CWD WORKDIR

# Update for each new release
SHORTREL="53"
LONGREL="5.3"

# No need to change anything below this line for new OS releases!

# Change if ftp.su.se is not the best place to get your files from!
URLBASE="http://ftp.su.se/pub/OpenBSD/${LONGREL}"
PATCHURL="ftp://ftp.openbsd.org/pub/OpenBSD/patches/${LONGREL}/common/*"

echo "Cleaning up previous build.."
rm -rf ${WORKDIR}

echo "Creating sandbox and diststuff.."
mkdir -p ${WORKDIR}
mkdir -p diststuff

echo "Getting current patches.."
mkdir ${WORKDIR}/patches
cd ${WORKDIR}/patches
ftp ${PATCHURL}
cd ${CWD}

binfiles="base${SHORTREL}.tgz
etc${SHORTREL}.tgz
comp${SHORTREL}.tgz
man${SHORTREL}.tgz"

srcfiles="src.tar.gz
sys.tar.gz"

cd diststuff
echo "Downloading binary release.."
for file in ${binfiles}; do
  if [ ! -f ${file} ] ; then 
    echo "Needed ${file}, didn't find it in current dir so downloading.."
    ftp ${URLBASE}/`machine`/${file}
  fi
done

echo "Downloading source.."
for file in ${srcfiles}; do
  if [ ! -f ${file} ] ; then 
    echo "Needed ${file}, didn't find it in current dir so downloading.."
    ftp ${URLBASE}/${file}
  fi
done

for file in ${binfiles}; do
  echo "checking ${file} file integrity"
  gunzip -t ${file}
  if [ $? != 0 ] ; then
   echo "${file} is corrupt! Exiting"
   exit
  fi
  echo "file integrity OK, extracting ${file} to ${WORKDIR}"
  tar zxpf ${file} -C ../${WORKDIR}
done

for file in ${srcfiles}; do
  echo "checking ${file} file integrity"
  gunzip -t ${file}
  if [ $? != 0 ] ; then
   echo "${file} is corrupt! Exiting"
   exit
  fi
  echo "file integrity OK, extracting ${file} to ${WORKDIR}"
  tar zxpf ${file} -C ../${WORKDIR}/usr/src
done

cd ..

echo "Setting up environment.."

umount ${CWD}/${WORKDIR}/dev
rm -rf ${CWD}/${WORKDIR}/dev-orig
mv ${CWD}/${WORKDIR}/dev ${CWD}/${WORKDIR}/dev-orig
mkdir ${CWD}/${WORKDIR}/dev
mount_mfs -o nosuid -s 32768 swap ${CWD}/${WORKDIR}/dev
cp -p ${CWD}/${WORKDIR}/dev-orig/MAKEDEV ${CWD}/${WORKDIR}/dev/MAKEDEV
cd ${CWD}/${WORKDIR}/dev
./MAKEDEV std
cp -p ${CWD}/mk-mini.conf ${CWD}/${WORKDIR}/mk-mini.conf
cp -p ${CWD}/build-release-injail.sh ${CWD}/${WORKDIR}/

# Don't want anything mounted to /mnt when we starts
umount /mnt

echo "Going into chroot to build.."
/usr/sbin/chroot ${CWD}/${WORKDIR} ./build-release-injail.sh

sleep 4 
cd
rm -rf ${CWD}/${WORKDIR}/dev/*
umount ${CWD}/${WORKDIR}/dev

echo "DONE! Now build kernel."

exit

