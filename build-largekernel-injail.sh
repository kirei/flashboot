#!/bin/sh

# Create dir if not there
mkdir -p obj

# Create a templist
cat list list.largekernel > list.temp

# Cleanup just in case the previous build failed
umount /mnt
vnconfig -u vnd0

make KCONF=${KERNEL} clean

# Make kernel
make termdefs bsd KCONF=${KERNEL} LIST=/list.temp NBLKS=${NBLKS} DISKPROTO=/disktabs/${DISKTAB} $2 $3 $4

exit

