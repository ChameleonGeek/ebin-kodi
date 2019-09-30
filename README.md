# ebin-kodi
Configure an EspressoBin v7 into an Ubuntu 16.04 LTS server to support kodi media file storage and management

This project configures a fresh, out of the box EspressoBin v7 SBC to support a Raspberry Pi-based home Kodi/OSMC media center among other file serving and management needs.  It is intended to supplement the lackluster EspressoBin documentation, and help Linux noobs quickly build a robust system.

My goal is to create a step-by-step guide which can be followed by tech amateurs so that they can use the EspressoBin.  The poor state of the EspressoBin documentation may lead potential users to believe that the hardware is similarly lackluster, which is far from the truth.  I have been abusing my EspressoBin for more than a year, and it has handled everything I've thrown at it far better than I ever expected from the otherwise poor support. My EspressoBin has been proven capable of far more than simple file serving.  This project will give the user the option to install other software which will make the EspressoBin even more useful.

This project will install several necessary programs such as:
- wget, which allows the user to download (this project's) configuration script
- Webmin, which allows a web-based configuration GUI for the EspressoBin
- Samba Server, which manages file sharing
- Open SSH Server which removes the USB tether for further configuration and management

## 1.  Prepare the MicroSD card
Since this project is intended to be paired with a Raspberry Pi, you should have one on hand.  Windows lacks the toolchain to properly prepare the card without long-lasting headaches, but Raspbian has what's needed.  These steps have been developed on a Raspberry Pi, and should be valid in most Linux distributions. **A USB MicroSD card reader is needed to prep the MicroSD card.**
- Boot the Raspberry pi with a functional Raspbian OS.
  - The Raspberry Pi Foundation has easy-to follow instructions using Windows/Apple/Linux at https://projects.raspberrypi.org/en/projects/raspberry-pi-setting-up
- If you encounter issues preparing the MicroSD card for the Espressobin, start over by following the steps above and just create a second Raspbian image, which will be overwritten as you proceed.
- Connect the MicroSD card reader to the USB port of the Raspberry Pi. Select "open in file manager" in the popup once the MicroSD card is connected.  Note the path to the card displayed in the file manager (Mount Point).
- Identify the device path of the MicroSD card *It **is not** /dev/mmcblk...*.  It is most likely /dev/sda1 (Device Path).
```
lsblk
```
- Run the following commands in the terminal:
```
wget https://github.com/ChameleonGeek/ebin-kodi/raw/master/ebin-sd-pi.sh
chmod +x ebin-sd-pi.sh
sudo sh ebin-sd-pi.sh
```
- Once the terminal has finished processing and displays success, the MicroSD card reader can be disconnected from the Raspberry Pi without further steps.

## 2.  Prep the EspressoBin to boot from MicroSD card
- Install the prepped MicroSD card into the EspressoBin.
- Connect an ethernet cable from your network to the EspressoBin's WAN port (the separate ethernet connector).
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

## 3.  First steps in Ubuntu
These first steps must be performed over the serial console.  The EspressoBin must be configured to connect to the internet, needs a quick fix and needs one piece of software to be manually added.

You will encounter errors stating "unable to resolve host localhost.localdomain: Connection refused" This is just a notice, and the issue will be corrected by the ebin-kodi script.

- Log in to Ubuntu.  The initial user is "root" with no password.  We'll give root a password later, but not during the first steps.
- Ubuntu has CPU throttling enabled by default.  This will create a kernel panic on the EspressoBin, so needs to be disabled.  Since the EspressoBin already draws very little power, CPU throttling is almost pointless.
- Networking needs to be configured before the EspressoBin can connect to the internet.
- Copy the code below and update it to suit your network in a text editor.  Update the variable values near the top of the code. _The main script will allow you to change this initial configuration later._
```
sudo su

# Disable CPU Throttling
update-rc.d ondemand disable

IP_ADDRESS="192.168.0.124"
NET_MASK="255.255.255.0"
NETWORK="192.168.0.0"
BROADCAST="192.168.0.255"
GATEWAY="192.168.0.1"

qry(){
  t=$(whiptail --title "$2" --inputbox "$3" 8 78 "$1" 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus == 0 ]; then
    echo "$t"
  else
    echo "$1"
	fi
}

# Temporary hostname to eliminate hosts file errors
# The user will have the option to update later
echo 'kodiserver' > /etc/hostname
echo -e "127.0.0.1\tkodiserver" > /etc/hosts

# ASK USER FOR INPUT
IP_ADDRESS=$(qry "$IP_ADDRESS" "IP Address" "Enter the IP Address for the EspressoBin")
NET_MASK=$(qry "$NET_MASK" "Network Mask" "Enter the Network Mask for your network")
NETWORK=$(qry "$NETWORK" "Network" "Enter the base network for the EspressoBin")
BROADCAST=$(qry "$BROADCAST" "Broadcast" "Enter the Broadcast IP Address for the network") 
GATEWAY=$(qry "$GATEWAY" "Gateway" "Enter the gateway (router) IP Address")

# CONFIGURE INITIAL NETWORK CONNECTION
echo 'auto eth0' > /etc/network/interfaces
echo 'iface eth0 inet manual' >> /etc/network/interfaces
echo '' >> /etc/network/interfaces
echo 'auto lo' >> /etc/network/interfaces
echo 'iface lo inet loopback' >> /etc/network/interfaces
echo '' >> /etc/network/interfaces
echo 'auto lan1' >> /etc/network/interfaces
echo 'iface lan1 inet static' >> /etc/network/interfaces
echo -e "\taddress $IP_ADDRESS" >> /etc/network/interfaces
echo -e "\tnetmask $NET_MASK" >> /etc/network/interfaces
echo -e "\tnetwork $NETWORK" >> /etc/network/interfaces
echo -e "\tbroadcast $BROADCAST" >> /etc/network/interfaces
echo -e "\tgateway $GATEWAY" >> /etc/network/interfaces
echo -e "\tdns-nameservers 8.8.8.8" >> /etc/network/interfaces
echo '' >> /etc/network/interfaces
echo 'pre-up /sbin/ifconfig lan1 up' >> /etc/network/interfaces
echo 'pre-up /sbin/ifconfig eth0 up' >> /etc/network/interfaces
```
- Copy the updated text from your text editor and paste into the terminal program.
- Reboot the EspressoBin by typing "reboot" and hit enter.

## 4.  Configure Ubuntu with the ebin-kodi script
- Log into Ubuntu (still root / no password).
- Update your package lists
```
sudo apt-get update
```
- Install wget
```
sudo apt-get install wget -y
```
- Download, prep and run main configuration script
```
wget https://raw.githubusercontent.com/ChameleonGeek/ebin-kodi/master/ebin-kodi.sh
chmod +x ebin-kodi.sh
sudo sh ebin-kodi.sh
```
- The script will walk you through the configuration process.  It will ask questions to guide you through the process, such as user names and network and domain configuration information.  To ensure better security, requests for passwords are made by Ubuntu or trusted installers rather than the script.
- Select "UTF-8" when asked what encoding should be used on the console, unless you are sure you need a different setting.
- You will be asked for a root password for MySQL server.  This request is made by the MySQL installer, not this script.
  - **Write down or remember this password**
- Cofiguring phpmyadmin
  - Ensure apache2 is selected (spacebar) and hit enter
  - Select yes when asked whether to use dbconfig-common to set up the database
  - Enter and confirm a password for the phpMyAdmin application to connect to MySQL.  You can let phpMyAdmin create a random password.  As a user or DBA, you won't need to use this password.
- Interactive User:
  - The root account shouldn't be used for routine interactions with the EspressoBin.  Enter a user name and password for this interactive account and answer the Ubuntu user information questions.
- Root User:
  - By default, Ubuntu sets the root account with no password.  This account should be password protected.  This should not be the same password as the interactive user.
## 5.  Configuration cleanup via Webmin
- Open a web browser and navigate to https://[espressobin ip address]:10000
- Enter the username and password created while running the script and click "Sign In"
- The webmin dashboard will load.  On the left of the page, click "Refresh Modules."  This will ensure that the proper modules display in the "Servers" section at the left.

## 6.  Do what you want with the EspressoBin
- A LAMP (Linux-Apache-MySQL-PHP) server is installed and can be browsed at http://[espressobin ip address]
- MySQL has been installed
  - phpMyAdmin is a web-based MySQL management tool, which can be accessed at http://[espressobin ip address]/phpmyadmin
- Webmin is a web-based administrative console, which can be accessed at https://[espressobin ip address]:10000
  - Most web browsers will complain that the EspressoBin's SSL certificate is not secure.  This is OK, even if annoying.
  - Login with the username and password you created during the script (not root)
  - Webmin has modules which manage connecting and (auto) mounting external drives, managing Samba file sharing, Open SSH access and many other functions.
  - Webmin allows you to install security and program updates without the need to understand Linux bash commands.
- Python3 is already installed as part of the base Ubuntu image.  Python3 pip has been installed to permit the addition of other Python modules.
