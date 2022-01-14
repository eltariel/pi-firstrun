#!/bin/bash

set +ex

# CONFIG
CONF_DIR=/boot/conf

. "${CONF_DIR}/vars.sh"
# END CONFIG

function update_config_txt() {
  if grep -q 'arm_64bit' /boot/config.txt
  then
    sed -i "s/arm_64bit=.*/arm_64bit=${ARM64}/" /boot/config.txt
  else
    echo "arm_64bit=${ARM64}" >> /boot/config.txt
  fi
}

function update_firmware() {
  sed -i "s/default/${FIRMWARE_VERSION}/" /etc/default/rpi-eeprom-update
  rpi-eeprom-update -a
}

function rename_pi_user() {
  usermod -l ${NEW_USER} -m -d "/home/${NEW_USER}" ${OLD_USER}
  groupmod -n ${NEW_USER} ${OLD_USER}
  
  echo "${NEW_USER}:${PASS}" | chpasswd -e
  
  rm -f "/etc/sudoers.d/010_${OLD_USER}-nopasswd"
  echo "${NEW_USER} ALL=(ALL) NOPASSWD: ALL" > "/etc/sudoers.d/010_${NEW_USER}-nopasswd"
}

function get_mac() {
	IFACE=${1:?"Need an interface"}
	ADDR_FILE=/sys/class/net/${IFACE}/address
	[[ -f "${ADDR_FILE}" ]] && ADDR=$(<"${ADDR_FILE}")
	[[ -n "${ADDR}" ]] && echo ${ADDR^^}
}

function update_hostname() {
  declare -A HOSTS
  while IFS=',' read MAC NAME
  do
    HOSTS[${MAC^^}]=${NAME}
  done < "${CONF_DIR}/hostnames"

  MYMAC=$(get_mac eth0 || get_mac wlan0)

  NEW_HOSTNAME=${HOSTS[${MYMAC}]:-${DEFAULT_HOSTNAME}}

  CURRENT_HOSTNAME=`cat "/etc/hostname" | tr -d " \t\n\r"`

  echo ${NEW_HOSTNAME} >"/etc/hostname"
  sed -i "s/127.0.1.1.*${CURRENT_HOSTNAME}/127.0.1.1\t${NEW_HOSTNAME}/g" "/etc/hosts"
}

function setup_ssh() {
  install -o "${NEW_USER}" -m 700 -d "/home/${NEW_USER}/.ssh"
  install -o "${NEW_USER}" -m 600 "${CONF_DIR}/authorized_keys" "/home/${NEW_USER}/.ssh/authorized_keys"
  echo 'PasswordAuthentication no' >>"/etc/ssh/sshd_config"
  systemctl enable ssh
}

function setup_wifi() {
  install -m 600 "${CONF_DIR}/wpa_supplicant.conf" "/etc/wpa_supplicant/wpa_supplicant.conf"
  rfkill unblock wlan
  for filename in /var/lib/systemd/rfkill/*:wlan
  do
    echo 0 > "$filename"
  done
}

function setup_locale() {
  rm -f "/etc/xdg/autostart/piwiz.desktop"
  rm -f "/etc/localtime"
  echo "${TIMEZONE}" > "/etc/timezone"
  dpkg-reconfigure -f noninteractive tzdata
  install "${CONF_DIR}/xkb.conf" "/etc/default/keyboard"
  dpkg-reconfigure -f noninteractive keyboard-configuration
}

function cleanup_config() {
  sed -i 's| systemd.run.*||g' "/boot/cmdline.txt"
  rm -f "/boot/customise.sh"
  rm -rf "${CONF_DIR}"
}

function do_config() {
  update_config_txt
  update_firmware
  rename_pi_user
  update_hostname
  setup_ssh
  setup_wifi
  setup_locale
  cleanup_config
}

do_config 2>&1 | tee /boot/customise.log
exit 0

