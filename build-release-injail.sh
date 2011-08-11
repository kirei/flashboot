#!/bin/sh

export DESTDIR=/
export BUILDCONF=/mk-mini.conf

cd /usr/src

echo "Patching src.."
for file in /patches/*.patch; do
  echo "patching ${file} to ${WORKDIR}/usr/src"
  patch -p0 < ${file}
done

#exit

set -xe

# rebuild obj dirs
cd /usr/src && make obj

# create dirs 
cd /usr/src/etc && make distrib-dirs

# build this thing
cd /usr/src && make build

# Make etc
cd /usr/src/etc && make distribution-etc-root-var

exit

