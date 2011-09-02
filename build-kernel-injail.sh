#!/bin/sh

# Create dir if not there
mkdir -p obj

# Create a templist
cat list > list.temp
# Include custom list if exist
if [ -r list.custom ]; then
        cat list.custom >> list.temp
fi

# Cleanup just in case the previous build failed
umount /mnt
vnconfig -u vnd0

make KCONF=${KERNEL} clean

# Make kernel
make termdefs bsd KCONF=${KERNEL} LIST=/list.temp $2 $3 $4

umount /mnt
vnconfig -u vnd0

exit
