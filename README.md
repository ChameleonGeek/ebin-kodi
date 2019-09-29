# ebin-kodi
Configure an EspressoBin v7 into an Ubuntu 16.04 LTS server to support kodi media file storage and management

This project configures a fresh, out of the box EspressoBin v7 SBC to support a home Kodi/OSMC media center among other file serving and management needs.  It is intended to supplement the lackluster EspressoBin documentation, and help Linux noobs quickly build a robust system.

My goal is to create a step-by-step guide which can be followed by tech amateurs so that they can use the EspressoBin.  The poor state of the EspressoBin documentation may lead potential users to believe that the hardware is similarly lackluster, which is far from the truth.  I have been abusing my EspressoBin for more than a year, and it has handled everything I've thrown at it far better than I ever expected from the otherwise poor support. My EspressoBin has been proven capable of far more than simple file serving.  This project will give the user the option to install other software which will make the EspressoBin even more useful.

This project will install several necessary programs such as:
- wget, which allows the user to download the configuration script
- Webmin, which allows a web-based configuration GUI for the EspressoBin
- Samba Server, which manages file sharing
- Open SSH Server which removes the USB tether for further configuration and management

## Prepare the MicroSD card

## Prep the EspressoBin to boot from MicroSD card
- Install the prepped MicroSD card into the EspressoBin.
- Connect a micro USB cable to the EspressoBin and your computer.
  - The green power LED will turn on, and your computer will detect that a device has been connected.  The EspressoBin *is not* powered via USB and *can not* be configured without 12v power.
- Connect 12v 2a power to the EspressoBin power connector.
- Identify the serial port that the EspressoBin is connected to.
- Open a serial terminal program and connect to the EspressoBin (previously identified port), 115200, 8, n, 1.
  - I have had best success in Windows with PuTTY.
- If the EspressoBin's "Marvell>>" prompt is not displayed in the terminal, press the EspressoBin reset button.
  - If you have tried to configure the EspressoBin to boot from other media, reset the EspressoBin and press a key when prompted to stop autoboot.
- Paste the following into the terminal program **_one command at a time_**:
```
setenv image_name boot/Image
setenv fdt_name boot/armada-3720-community.dtb
setenv bootmmc 'mmc dev 0; ext4load mmc 0:1 $kernel_addr $image_name;ext4load mmc 0:1 $fdt_addr $fdt_name;setenv bootargs $console root=/dev/mmcblk0p1 rw rootwait; booti $kernel_addr - $fdt_addr'
setenv bootcmd 'mmc dev 0; ext4load mmc 0:1 $kernel_addr $image_name;ext4load mmc 0:1 $fdt_addr $fdt_name;setenv bootargs $console root=/dev/mmcblk0p1 rw rootwait; booti $kernel_addr - $fdt_addr'
saveenv
```
- Type "reset" and hit enter.  The EspressoBin will now boot into Ubuntu.

## First steps in Ubuntu
These first steps must be performed over the serial console.  The EspressoBin must be configured to connect to the internet, needs a quick fix and needs one piece of software to be manually added.
- Log in to Ubuntu.  The initial user is "root" with no password.  We'll give root a password later, but not during the first steps.
- Ubuntu has CPU throttling enabled by default.  This will create a kernel panic on the EspressoBin, so needs to be disabled.  Since the EspressoBin already draws very little power, CPU throttling is almost pointless.
- Networking needs to be configured before the EspressoBin can connect to the internet.
- Copy the code below and update it to suit your network in a text editor.  Update anywhere enclosed in [[ ]] brackets, removing the brackets. _The main script will allow you to change this initial configuration later._
```
sudo su
# Disable CPU Throttling
update-rc.d ondemand disable

# CONFIGURE INITIAL NETWORK CONNECTION
echo 'auto eth0' > /etc/network/interfaces
echo 'iface eth0 inet manual' >> /etc/network/interfaces
echo '' >> /etc/network/interfaces
echo 'auto lo' >> /etc/network/interfaces
echo 'iface lo inet loopback' >> /etc/network/interfaces
echo '' >> /etc/network/interfaces
echo 'auto lan1' >> /etc/network/interfaces
echo 'iface lan1 inet static' >> /etc/network/interfaces
echo 'address [[192.168.0.124]]' >> /etc/network/interfaces
echo 'netmask [[255.255.255.0]]' >> /etc/network/interfaces
echo 'network [[192.168.0.0]]' >> /etc/network/interfaces
echo 'broadcast [[192.168.0.255]]' >> /etc/network/interfaces
echo 'gateway [[192.168.0.1]]' >> /etc/network/interfaces
echo 'dns-nameservers 8.8.8.8' >> /etc/network/interfaces
echo '' >> /etc/network/interfaces
echo 'pre-up /sbin/ifconfig lan1 up' >> /etc/network/interfaces
echo 'pre-up /sbin/ifconfig eth0 up' >> /etc/network/interfaces
```
- Copy the updated text from your text editor and paste into the terminal program.
- Reboot the EspressoBin by typing "reboot" and hit enter.
- Log into Ubuntu (still root / no password).
- Update your package lists
```
sudo apt-get update
```
- Install wget (git???)
```
sudo apt-get install wget -y
```
- Download, prep and run main configuration script
```
wget <script in process>
chmod +x <script in process>
sudo sh <script in process>
```
- The script will walk you through the configuration process.  It will ask questions to guide you through the process, such as user names and passwords as well as network and domain configuration information.




