#!/bin/sh

DEV=`df | grep /flash | sed 's/\(^\/dev\/[a-z0-9]*\).*/\1/g'`

mount -u -o ro $DEV /flash
