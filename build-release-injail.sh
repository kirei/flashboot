#!/bin/sh

export MAKECONF=/mk-mini.conf

cd /usr/src

echo "Patching src.."
for file in /patches/*.patch.sig; do
  if [ `egrep -c '^RCS file: /cvs/OpenBSD/xenocara' ${file}` -ge 1 ]; then
	echo "skipping xenocara patch $file"
	continue;
  fi
  echo "patching ${file} to ${WORKDIR}/usr/src"
  signify -Vep /etc/signify/openbsd-55-base.pub -x ${file} -m - | \
      (cd /usr/src && patch -p0)
done

#exit

set -xe

# rebuild obj dirs
cd /usr/src && make obj

# create dirs 
cd /usr/src/etc && env DESTDIR=/ make distrib-dirs

# build this thing
cd /usr/src && make build

# Make etc
cd /usr/src/etc && env DESTDIR=/ make distribution-etc-root-var

exit
