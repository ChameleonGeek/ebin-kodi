#!/bin/bash
# ==============================================================================
# ==============================================================================
# 
#                             EspressoBin Config
#                           Kodi/OSMC Media Server
#                              September, 2019
#                   https://github.com/ChameleonGeek/ebin-kodi
# 
#     This script uses a Raspberry Pi SBC to download the EspressoBin 
# Ubuntu 16.04 LTS server image, prepare a MicroSD card for the EspressoBin
# and export the image files to the MicroSD card.
# 
#     This script is the first step of configuring the EspressoBin.  It expects
# a Raspberry Pi running Raspbian connected to the internet.  The MicroSD card
# must have a single partition and must be formatted with a filesystem the RasPi
# can read and write.  The MicroSD card needs to be connected to the RasPi with
# a USB MicroSD reader.
# 
# ==============================================================================
# ==============================================================================
cd /home/pi

DLSTATUS=0
EXTRACTED=0

# Determine if the image needs to be downloaded/extracted
if [ -e 'rootfs.tar.bz2' ]; then
	EXTRACTED=1
fi

if [ -e 'ebin-ubuntu-16.04.3.zip' ]; then
	DLSTATUS=1
fi

if [ $DLSTATUS == 0 && $EXTRACTED == 0 ]; then
	# IMAGE HAS NOT BEEN DOWNLOADED OR EXTRACTED
	wget http://espressobin.net/wp-content/uploads/2017/10/ebin-ubuntu-16.04.3.zip
fi

if [ $EXTRACTED == 0 ]; then
	# IMAGE HAS BEEN DOWNLOADED BUT NOT EXTRACTED
	unzip ebin-ubuntu-16.04.3.zip	
fi

if [ -e 'rootfs.tar.bz2' ]; then
	echo "The EspressoBin file system has not been extracted."
  exit
fi

# OS IMAGE HAS BEEN DOWNLOADED AND UNZIPPED.  NOW PREPARE THE SD CARD
MOUNTPOINT=$(whiptail --title "Mount Point" --inputbox "Enter the current mount point" 8 78 "" 3>&1 1>&2 2>&3)
esa=$?
DEVICEPATH=$(whiptail --title "Device Path" --inputbox "Enter the device path for the SD card" 8 78 "/dev/sda1" 3>&1 1>&2 2>&3)
esb=$?
if [ ((esa + esb)) == 0 ]; then
  sudo umount "${MOUNTPOINT}"
  sudo mkdir /ebincard
  sudo mkfs -t ext4 "${DEVICEPATH}"
  sudo mount "${DEVICEPATH}" /ebincard
  cd /ebincard
  sudo tar -xvf /home/pi/rootfs.tar.bz2
  cd /home/pi
  sudo umount /ebincard
  sudo rm -rf /ebincard
  echo "Card has been prepped and is safe to disconnect."
else
  echo "Card prep failed."
  if ![ -e 'ebin-ubuntu-16.04.3.zip' ]; then
	  echo "The image zip file has not been downloaded."
  fi
fi
