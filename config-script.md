## Configuring the EspressoBin with espressobin.sh

On first boot, the EspressoBin won't automatically connect to your network and is running an extremely lean Ubuntu OS with very few tools.  Two scripts have been created to make the EspressoBin much more useful.  The first starts up networking on the EspressoBin, installs wget to download the larger script, and then executes the larger script.  The second script gives you a lot of flexibiity, installing one of four main configurations with the option to install more software.

This step assumes that you have just completed step 2 and haven't made _any_ updates to the EspressoBin.  Any changes you make to the EspressoBin before running the scripts may interfere with the script.  The script will:
- Ask which primary configuration type you want to install
- Ask for network configuration information, which will be implemented and tested
- Require that you create an interactive user other than root, with sudo permissions.  It secures both the root user and the interactive user with a password

***I strongly advise you opt to install webmin if you are not highly accustomed to working with the Linux command line.  Webmin creates a web-based GUI that you can use to install updates, install new software and configure options in tools like Samba, FTP and SSH***

Log into Ubuntu on the the EspressoBin.  The user is "root" with no password.  An interactive user will be created by the script, and you will be rquired to give root a password.

#### Basic Install
The Basic Install performs the least configuration, essentially setting up the EspressoBin as a basic Ubuntu 16.04 LTS server with a few tools to make further management and upgrade easier.
- It asks if you want to install Webmin
- It adds "universe" repositories to the sources list, which allows a broader selection of software through apt-get
- It performs apt-get upgrade to ensure that all installed software is up-to-date
- It installs the nano text editor for easier editing of files from the terminal
- It installs pip for Python3, which is already installed on the EspressoBin
- It installs tasksel, which makes it easier to install larger server softare suites

#### File Server
The File Server Install configures the EspressoBin as a Samba File Server with the option to install additional tools
- It offers all of the options/automatically installed software in the Basic Install
- It allows the installation of OpenSSH server
- It installs Samba File Server and adds the interactive user as a Samba user.

#### Custom Install
This option gives the greatest flexibility, offering a number of packages to install
- It offers all of the options/automatically installed software in the Basic Install
- It also offers the installation of:
  - Samba File Server (adding the interactive user as a Samba user)
  - LAMP web server suite
  - MySQL if LAMP is not selected
  - phpMyAdmin if mySQL is installed separately or as part of LAMP
  - OpenSSH server
  - OpenVPN server

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
- Select yes when asked whether to use dbconfig-common to set up the database
- Enter and confirm a password for the phpMyAdmin application to connect to mySQL. You can let phpMyAdmin create a random password. ***As a user or DBA, you won't need to use this password.***

#### Interactive User:
The root account shouldn't be used for routine interactions with the EspressoBin. Enter a user name and password for this interactive account and answer the Ubuntu user information questions.
***Write down or remember this username and password. It is the interactive superuser account.***

#### Root User:
By default, Ubuntu sets the root account with no password. This account should be password protected. This should not be the same password as the interactive user.
***Write down or remember this password.***
