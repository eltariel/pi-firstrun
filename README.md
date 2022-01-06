# Pi Firstrun

This is a first-run startup script for a raspberry pi image that will set a collection of defaults
out of the box. It uses the same mechanism to customise the image as the [Raspberry Pi Imager][img], i.e.
using the `systemd.run` kernel parameter and booting systemd to `kernel-command-line.target`. (Note: docs
suggest that explicitly referencing `kernel-command-line.target` is unnecessary).

It does the following:

- Sets the hostname based on the device's ethernet MAC address (don't try it on a pi zero!)
- Unblocks WiFi and installs the config
- Sets the system timezone and keyboard config
- Renames the `pi` user and sets a password
- Sets the SSH server to only accept pubkey auth, and installs a list of authorized keys for the new user
- Cleans up after itself, leaving output in `/boot/firstrun.log`


# Compatibility

This works works with recent Raspberry Pi OS Lite (bullseye) images. It'll probably work on other
variants of bullseye as well.


# Usage

## Automagic

- Run `./patch-img.sh`. Note this step is linux only - use a VM if you're on windows or macos.
- Write the image to your SD card:
  - linux: `dd if=<image file>.img of=/dev/<sd card device> bs=4M status=progress`
  - macos: `./flash-macos.sh <image file>.img /dev/rdisk<n>` where <n> is the disk number for your SD card.
  - Windows: TBD
- Insert the SD into the Pi and wait.


## Manual (don't do this)

- Write a *customised* image to your SD card with the Raspberry Pi Imager
- Make a copy of the `conf.sample` directory called `conf` and update all of the files in there.
- Copy `conf` and `customise.sh` to the root of the SD card.
- Change `firstrun.sh` to `customise.sh` in `cmdline.txt`.
- Insert the SD into the Pi and wait.


# TODO:
[] Better config
[] Script to flash the SD and copy the cfg in one hit
[] Support Pi's without ethernet (zero, zero W, zero 2, 3A)
[] Set device locale
