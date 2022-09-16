#!/bin/bash

### It may harm. You were warned :-)))

DESIRED_FS=xfs
DSKLetters="a b c d e f g h i j k l m n o p"
BLOCKDEV_PREFIX=/dev/sd
MOUNTDIR_TEMPLATE=/mnt/disk
MOUNTDIR_INDEX=0 

oops() {
  printf "Something went wrong :-))\n\n"
}

create_partition() {
parted -a optimal ${BLOCKDEV_PREFIX}$1 mklabel gpt mkpart primary $DESIRED_FS 0% 100% > /dev/null
}

for lastLetter in $DSKLetters; do
  
  printf "  * processing ${BLOCKDEV_PREFIX}${lastLetter}: "
  # check block device
  [ -b ${BLOCKDEV_PREFIX}${lastLetter} ] || { printf "\t- Device ${BLOCKDEV_PREFIX}${lastLetter} not found\n\n"; continue; }
  # check partition table
  [[ $(sfdisk -d ${BLOCKDEV_PREFIX}${lastLetter}) == "" ]] || { printf "\t- disk partitioned, skipping\n\n"; continue; }
  # check filesystem existence
  blkid -t TYPE=xfs ${BLOCKDEV_PREFIX}${lastLetter} && { printf "\t- partition 1 already formatted\n\n"; continue; }
  # prepare partition 1 if no any
  create_partition ${lastLetter} || { oops; continue; }
  # prepare partition 1 if no any
  mkfs.${DESIRED_FS} ${BLOCKDEV_PREFIX}${lastLetter}1 > /dev/null && printf "\t- Successfully formatted as ${DESIRED_FS}\n" || { oops; continue; }

  echo "${BLOCKDEV_PREFIX}${lastLetter}1 ${MOUNTDIR_TEMPLATE}${MOUNTDIR_INDEX} ${DESIRED_FS} defaults 0 0" >> /etc/fstab && \
    { mkdir -p ${MOUNTDIR_TEMPLATE}${MOUNTDIR_INDEX}; let MOUNTDIR_INDEX++; printf "\t- Added mountpoint ${MOUNTDIR_TEMPLATE}${MOUNTDIR_INDEX} to fstab\n\n"; } || { oops; continue; }
done

mount -a && echo "Sucessfully mounted all volumes" || oops
