## Prep the microSD Card
Windows doesn't support the ext4 filesystem by default, and I haven't found a toolchain that won't produce blue screens of death at random times.  I'm stuck with Windows on my main systems, but love playing with the Raspberry Pi.  I have a couple sitting around for random projects.  The Ras Pi is easy to get up and running with a Windows/Apple/Linux PC thanks to the instructions provided by the Raspberry Pi foundation at https://projects.raspberrypi.org/en/projects/raspberry-pi-setting-up.

With a Ras Pi, all that is needed is a USB microSD reater and an internet connection, and you can format and image the card for the EspressoBin, which takes about two minutes.  Note that you can't simply use the Ras Pi microSD slot, since that holds the Ras Pi boot image.

If you're using an Apple or Linux PC, you can skip the Raspberry Pi and should be able to perform this process on your PC.  I have tested it on Ubuntu 18.04 and 16.04 desktop (live CD image), but not on any Apple OS.

**_If you have any issues with the EspressoBin microSD card during this process, you can start over and prep it as if for a Raspberry Pi_**

**BE AWARE: you are responsible for ensuring that you don't reformat a drive with important data!  Make sure that you select the correct drive (microSD card), as all data will be erased**

These instructions are for using a Raspberry Pi and may need to be changed for other Linux distributions or Apple OS.
- Open a terminal window
- Identify the device path for the microSD card. **_It is likely to be /dev/sda1_**
```
lsblk
```
  - Download and execute [this](ebin-sd-pi.sh) script 
```
wget https://github.com/ChameleonGeek/ebin-kodi/raw/master/ebin-sd-pi.sh
chmod +x ebin-sd-pi.sh
sudo sh ebin-sd-pi.sh
```
The script will walk through the process, asking just a couple of questions.
  - It will download the image from espressobin.net if you haven't already done so.
  - It will extract the image file from the download if necessary
  - It will ask you for the mount point of the microSD card
  - It will unmount and reformat the microSD card
    - You need to answer "yes" to reformat the card
  - It will copy all Ubuntu files to the card
  - It will unmount the microSD card and tell you when you can remove it from the system
