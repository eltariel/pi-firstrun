#!/bin/bash

set -e

#TODO: configure this properly
IMAGE_URL=https://downloads.raspberrypi.org/raspios_lite_armhf/images/raspios_lite_armhf-2021-11-08/2021-10-30-raspios-bullseye-armhf-lite.zip
#IMAGE_URL=https://downloads.raspberrypi.org/raspios_armhf/images/raspios_armhf-2021-11-08/2021-10-30-raspios-bullseye-armhf.zip
IMAGE_FILE=$(sed -e 's|^.*/\(.*\)\.zip$|\1|' <<<"${IMAGE_URL}")-custom.img

PI_TEMP=$(mktemp -dt pi-customise.XXXX)
MOUNTPOINT=${PI_TEMP}/mount

echo "Downloading image"
WORKING_IMAGE=${PI_TEMP}/$(basename "${IMAGE_FILE}")
wget "${IMAGE_URL}" -O "${PI_TEMP}/img.zip"
unzip -p "${PI_TEMP}/img.zip" > "${WORKING_IMAGE}"

echo
echo "Mounting boot partition from image file to ${MOUNTPOINT}"
KPARTX=$(sudo kpartx -av "${WORKING_IMAGE}")
BOOT_PART=$(cut -d ' ' -f 3 <<<${KPARTX} | head -n 1)
mkdir -p ${MOUNTPOINT}
sudo mount -o "umask=0000" "/dev/mapper/${BOOT_PART}" "${MOUNTPOINT}"

echo
echo "Updating config"
cp -r conf customise.sh "${MOUNTPOINT}"
sed -i.orig '1s|$| cgroup_enable=cpuset cgroup_memory=1 cgroup_enable=memory systemd.run=/boot/customise.sh systemd.run_success_action=reboot systemd.unit=kernel-command-line.target|' "${MOUNTPOINT}/cmdline.txt"

echo
echo "Cleaning up"
sudo umount "${MOUNTPOINT}"
sudo kpartx -da "${WORKING_IMAGE}"

mv "${WORKING_IMAGE}" "${IMAGE_FILE}"
rm -r "${PI_TEMP}"
echo "Done."
