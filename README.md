# ebin-kodi
Configure an EspressoBin v7 into an Ubuntu 16.04 LTS server to support kodi media file storage and management

This project configures a fresh, out of the box EspressoBin v7 SBC to support a Raspberry Pi-based home Kodi/OSMC media center among other file serving and management needs.  It is intended to supplement the lackluster EspressoBin documentation, and help Linux noobs quickly build a robust system.  This process takes between 20 minutes and one hour depending upon how prepared the user is to answer configuration questions and which components are selected for installation.

My goal is to create a step-by-step guide which can be followed by tech amateurs so that they can use the EspressoBin.  The poor state of the EspressoBin documentation may lead potential users to believe that the hardware is similarly lackluster, which is far from the truth.  I have been abusing my EspressoBin for more than a year, and it has handled everything I've thrown at it far better than I ever expected from the otherwise poor support. My EspressoBin has been proven capable of far more than simple file serving.  This project will give the user the option to install other software which will make the EspressoBin even more useful.

This project offers four configuration types, each with preselected and optional software:
- Basic install - the simplest configuration with functional network configuration and minimal software installed
- File Server - Samba file server with functional networking and a few software options
- Domain Controller - The most software installed, with functional networking and configured as a Windows 2008 R2 compatible Domain Controller
- Custom Installation - The most flexible option, with functional networking and lots of software choices

Each of these main install types are explained in greater detail [here](https://github.com/ChameleonGeek/ebin-kodi/blob/master/config-script.md).

Note that none of the optional software is completely configured once this process is complete.  Each main component has additional configuration options which are impossible to accommodate in a single script intended for distribution.  Webmin is an optionally installed element, and all final configuration can be accomplished through the Webmin Web-based interface.

## 1.  Prepare the MicroSD card
After installation, the largest image created by this project is a bit less than 5GB.  I recommend at least 32GB of you intend to do more than basic file serving.

Instructions for prepping the microSD card using a Raspberry Pi are [here](https://github.com/ChameleonGeek/ebin-kodi/blob/master/sd-prep.md).  These instructions should work on any Linux PC or Apple with minor adjustments.

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
These first steps must be performed over the serial console.

You will encounter errors stating "unable to resolve host localhost.localdomain: Connection refused" This is just a notice, and the issue will be corrected by the ebin-kodi script.

- Log in to Ubuntu.  The initial user is "root" with no password.  We'll give root a password later, but not during the first steps.
- Copy the code below and paste into the terminal. This code will configure the EspressoBin to use DHCP, will update software sources and download/run the main configuration script.  _This script will make some temporary network settings (DHCP/temporary hostname). The main script will allow you to change this initial configuration later._
```
qry(){
	t=$(whiptail --title "$2" --inputbox "$3" 8 78 "$1" 3>&1 1>&2 2>&3)
	echo "$t" > "${2}"
	echo "$t"
}

# CONFIGURE INITIAL NETWORK CONNECTION
netcfg(){
	# Temporary hostname to eliminate hosts file errors
	# The user will have the option to update later
	echo 'kodiserver' > /etc/hostname
	echo -e "127.0.0.1\tkodiserver" > /etc/hosts

	ip link set dev eth0 up
	ip link set dev lan1 up
	dhclient lan1
	echo -e "\033[1;32mRestarting Networking.\033[0m"
	/etc/init.d/networking restart
	echo -e "\033[1;32mChecking if EspressoBin is on line.\033[0m"
	ping -c 3 github.com
}

runconfig(){
	clear
	echo -e "\033[1;32mPerforming temporary (DHCP) network configuration."
	echo -e "This will take a moment.\033[0m"
	netcfg
	echo -e "\033[1;32mUpdating Ubuntu Package Lists\033[0m"
	apt-get update
	echo -e "\033[1;32mInstalling wget/downloading script\033[0m"
	apt-get install wget -y
	#wget https://raw.githubusercontent.com/ChameleonGeek/ebin-kodi/master/ebin-kodi.sh -q
	#chmod +x ebin-kodi.sh
	#sudo sh ebin-kodi.sh
	wget http://chameleonoriginals.com/c/ebin-kodi.s
	chmod +x ebin-kodi.s
	sudo sh ebin-kodi.s
}

runconfig

```
- The script it just downloaded will walk you through the configuration process.  It will ask questions to guide you through the process, such as user names and network and domain configuration information.  To ensure better security, requests for passwords are made by Ubuntu or trusted installers rather than the script.
- Select "UTF-8" when asked what encoding should be used on the console, unless you are sure you need a different setting.
- Select your timezone when prompted.
- You will be asked for a root password for MySQL server.  This request is made by the MySQL installer, not this script.
  - **Write down or remember this password**
- Cofiguring phpmyadmin
  - Ensure apache2 is selected (spacebar) and hit enter
  - Select yes when asked whether to use dbconfig-common to set up the database
  - Enter and confirm a password for the phpMyAdmin application to connect to MySQL.  You can let phpMyAdmin create a random password.  As a user or DBA, you won't need to use this password.
- Interactive User:
  - The root account shouldn't be used for routine interactions with the EspressoBin.  Enter a user name and password for this interactive account and answer the Ubuntu user information questions.
  - **Write down or remember this username and password.  It is the interactive superuser account.**
- Root User:
  - By default, Ubuntu sets the root account with no password.  This account should be password protected.  This should not be the same password as the interactive user.
  - **Write down or remember this user name and password.**
## 4.  Configuration cleanup via Webmin
- Open a web browser and navigate to https://[espressobin ip address]:10000
- Enter the interactive user name and password created while running the script and click "Sign In"
- The webmin dashboard will load.  On the left of the page, click "Refresh Modules."  This will ensure that the proper modules display in the "Servers" section at the left.

## 5.  Do what you want with the EspressoBin
- A LAMP (Linux-Apache-MySQL-PHP) server is installed and can be browsed at http://[espressobin ip address]
- MySQL has been installed
  - phpMyAdmin is a web-based MySQL management tool, which can be accessed at http://[espressobin ip address]/phpmyadmin
- Webmin is a web-based administrative console, which can be accessed at https://[espressobin ip address]:10000
  - Most web browsers will complain that the EspressoBin's SSL certificate is not secure.  This is OK, even if annoying.
  - Login with the username and password you created during the script (not root)
  - Webmin has modules which manage connecting and (auto) mounting external drives, managing Samba file sharing, Open SSH access and many other functions.
  - Webmin allows you to install security and program updates without the need to understand Linux bash commands.
- Python3 is already installed as part of the base Ubuntu image.  Python3 pip has been installed to permit the addition of other Python modules.
