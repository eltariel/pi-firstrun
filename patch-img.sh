#!/bin/bash

set -e

#TODO: configure this properly

MOUNTPOINT=/mnt/pi-customise
IMAGE_URL=https://downloads.raspberrypi.org/raspios_lite_armhf/images/raspios_lite_armhf-2021-11-08/2021-10-30-raspios-bullseye-armhf-lite.zip
IMAGE_ZIP=${IMAGE_URL##*/}
IMAGE_FILE=${IMAGE_ZIP%.zip}.img

echo "Downloading image"
wget "${IMAGE_URL}"
unzip "${IMAGE_ZIP}"

echo
echo "Mounting boot partition from image file to ${MOUNTPOINT}"
KPARTX=$(sudo kpartx -av "${IMAGE_FILE}")
BOOT_PART=$(cut -d ' ' -f 3 <<<${KPARTX} | head -n 1)
sudo mkdir -p ${MOUNTPOINT}
sudo mount -o "umask=0000" "/dev/mapper/${BOOT_PART}" "${MOUNTPOINT}"

echo
echo "Updating config"
cp -r conf customise.sh "${MOUNTPOINT}"
sed -i.orig '1s|$| systemd.run=/boot/customise.sh systemd.run_success_action=reboot systemd.unit=kernel-command-line.target|' "${MOUNTPOINT}/cmdline.txt"

echo
echo "Unmounting image"
sudo umount "${MOUNTPOINT}"
sudo kpartx -da "${IMAGE_FILE}"
echo "Done."
