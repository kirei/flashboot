#!/bin/sh

# Create dir if not there
mkdir -p obj

# Cleanup just in case the previous build failed
umount /mnt
vnconfig -u vnd0

make KCONF=${KERNEL} clean

# Make kernel
make termdefs bsd KCONF=${KERNEL} $2 $3 $4

umount /mnt
vnconfig -u vnd0

exit
