# ebin-kodi
Configure an EspressoBin v7 into an Ubuntu 16.04 LTS server to support kodi media file storage and management

This project configures a fresh, out of the box EspressoBin v7 SBC to support a Raspberry Pi-based home Kodi/OSMC media center among other file serving and management needs.  It is intended to supplement the lackluster EspressoBin documentation, and help Linux noobs quickly build a robust system.  This process takes between 20 minutes and one hour depending upon how prepared the user is to answer configuration questions and which components are selected for installation.

My goal is to create a step-by-step guide which can be followed by tech amateurs so that they can use the EspressoBin.  The poor state of the EspressoBin documentation may lead potential users to believe that the hardware is similarly lackluster, which is far from the truth.  I have been abusing my EspressoBin for more than a year, and it has handled everything I've thrown at it far better than I ever expected from the otherwise poor support and low price. My EspressoBin has been proven capable of far more than simple file serving.  This project will give the user the option to install other software which will make the EspressoBin even more useful.

This project offers three configuration types, each with preselected and optional software:
- Basic install - the simplest configuration with functional network configuration and minimal software installed.
- File Server - Samba file server with functional networking and a few software options.
- Custom Installation - The most flexible option, with functional networking and lots of software choices.

Each of these main install types are explained in greater detail below.

***Note that none of the optional software is completely configured once this process is complete.***  Each main component has additional configuration options which are impossible to accommodate in a single script intended for distribution.  Webmin is an optionally installed element, and all final configuration can be accomplished through the Webmin Web-based interface.

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

## 3. Configuring the EspressoBin with espressobin.sh

On first boot, the EspressoBin won't automatically connect to your network and is running an extremely lean Ubuntu OS with very few tools.  Two scripts have been created to make the EspressoBin a solid Ubuntu system.  The first lets you download the main script.  The second script gives you a lot of flexibiity, installing one of three main configurations with the option to install more software.

This step assumes that you have just completed step 2 and haven't made _any_ updates to the EspressoBin.  Any changes you make to the EspressoBin before running the scripts may interfere with the script.  The downloaded script will:
- Ask which primary configuration type you want to install.
- Ask for network configuration information, which will be implemented and tested.
- Require that you create an interactive user other than root, with sudo permissions.  It secures both the root user and the interactive user with a password.

***I strongly advise you opt to install webmin if you are not highly accustomed to working with the Linux command line.  Webmin creates a web-based GUI that you can use to install updates, install new software and configure options in tools like Samba, FTP and SSH***

Log into Ubuntu on the the EspressoBin.  The user is "root" with no password.  An interactive user will be created by the script, and you will be rquired to give root a password as one of the final configuration steps.

#### Basic Install
The Basic Install performs the least configuration, essentially setting up the EspressoBin as a basic Ubuntu 16.04 LTS server with a few tools to make further management and upgrade easier.
- It asks if you want to install Webmin.
- It adds "universe" repositories to the sources list, which allows a broader selection of software through apt-get.
- It performs apt-get upgrade to ensure that all installed software is up-to-date.
- It installs the nano text editor for easier editing of files from the terminal.
- It installs pip for Python3, which is already installed on the EspressoBin.
- It installs tasksel, which makes it easier to install larger server softare suites.

#### File Server
The File Server Install configures the EspressoBin as a Samba File Server with the option to install additional tools.
- It offers all of the options/automatically installed software in the Basic Install.
- It allows the installation of OpenSSH server.
- It installs Samba File Server and adds the interactive user as a Samba user.

#### Custom Install
This option gives the greatest flexibility, offering a number of packages to install.
- It offers all of the options/automatically installed software in the Basic Install.
- It also offers the installation of:
  - Samba File Server (adding the interactive user as a Samba user).
  - LAMP web server suite.
  - MySQL if LAMP is not selected.
  - phpMyAdmin if mySQL is installed separately or as part of LAMP.
  - OpenSSH server.
  - OpenVPN server.

## The first script
On first boot, the EspressoBin can't download anything without performing multiple steps ahead of time.  Copy the following and paste it into the terminal on the EspressoBin.  It will prep the EspressoBin so that it can download and execute the larger configuration script.
```
preconfig(){
	clear
	echo "Starting networking.  This will take a moment"
	ip link set dev eth0 up
	ip link set dev lan1 up
	dhclient lan1
	apt-get update
	sleep 5
	apt-get install wget -y
	
	wget https://raw.githubusercontent.com/ChameleonGeek/ebin-kodi/master/espressobin.sh
	chmod +x espressobin.sh
	bash espressobin.sh
}
preconfig

```
This code will enable a DHCP connection to your network (which will be changed to static IP later), update available package lists, install wget, then download and execute the main configuration script.

## The second script
The second script will start automatically as soon as it is downloaded.  It starts asking a series of questions, which will change according to what you select.  I have made efforts to concentrate as many questions as possible at the beginning of the process.  The first set of questions should be relatively self-explanatory.  As the installation and configuration progresses, some of the questions asked by installed tools may be a bit less self-explanatory.  Here are some recommendations for answering these questions:

#### Console Encoding:
Unless you know you should select otherwise, select "UTF-8."  This is the setting currently being used in your connection between the EspressoBin and your PC.

#### mySQL root Password:
Enter a password for the mySQL user "root."  The mySQL server shouldn't have a blank password for this user, and shouldn't have the same password as any Ubuntu user.  This password can be changed later if desired via the terminal, Webmin or phpMyAdmin. 

***Write down or remember this password***

#### Cofiguring phpMyAdmin:
- Ensure apache2 is selected (spacebar) and hit enter.
- Select yes when asked whether to use dbconfig-common to set up the database.
- Enter and confirm a password for the phpMyAdmin application to connect to mySQL. You can let phpMyAdmin create a random password. 

***As a user or DBA, you won't need to use this password.***

#### Interactive User:
The root account shouldn't be used for routine interactions with the EspressoBin. Enter a user name and password for this interactive account and answer the Ubuntu user information questions.

***Write down or remember this username and password. It is the interactive superuser account.***

#### Root User:
By default, Ubuntu sets the root account with no password. This account should be password protected. This should _not_ be the same password as the interactive user.

***Write down or remember this password.***

#### Samba Password:
If you opted to install Samba, a user account was automatically created in Samba (same user name as the interactive user).  This user needs a password.  It is common practice to ensure that the Ubuntu and Samba passwords are the same for the same user name.

***Write down or remember this password.***

## 4.  Configuration cleanup via Webmin
- Open a web browser and navigate to https://[espressobin ip address]:10000
  - You will receive warnings from your web browser that the certificate being used by webmin is not valid.  Creating a certificate for the EspressoBin is a highly variable process depending upon your network and your needs.
- Enter the interactive user name and password created while running the script and click "Sign In."
- The webmin dashboard will load.  On the left of the page, click "Refresh Modules."  This will ensure that the proper modules display in the "Servers" section at the left.
- Any of the components installed by this project can be administered and configured via the webmin interface.
- It is easy to forget to install security updates.  In Webmin, under System/Software Package Updates/Scheduled Upgrades, you can enable automatic update checks, and what actions should be taken.

## 5.  Do what you want with the EspressoBin
- If you installed LAMP, the EspressoBin's web server can be viewed at http://[espressobin ip address]
- If you installed phpMyAdmin, it can be viewed at http://[espressobin ip address]/phpmyadmin
- If you installed OpenSSH Server, you can log in as root or the interactive user.
