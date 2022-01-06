#!/bin/bash

set -e

IMAGE=${1:?"Need an image file name as first arg"}
RDISK=${2:?"Need a disk device as second arg, e.g. /dev/rdisk3"}

grep '^/dev/rdisk[0-9]*$' <<<"${RDISK}" > /dev/null
DISK=$(sed 's/rdisk/disk/' <<<"${RDISK}")

IMAGE=$(readlink -e ${IMAGE})

diskutil list $RDISK

read -p "Write to this disk [Y/N]? " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    exit 1
fi


diskutil umountDisk $RDISK
dd if=${IMAGE} of=${RDISK} bs=4M status=progress
diskutil eject $DISK

