#!/bin/bash
# ==============================================================================
# ==============================================================================
# 
#                             EspressoBin Config
#                           Kodi/OSMC Media Server
#                              September, 2019
#                   https://github.com/ChameleonGeek/ebin-kodi
# 
#     This script performs the basic software installation and configuration 
# necessary to make a new EspressoBin v7 into an Ubuntu 16.04 LTS server with 
# various software necessary to support a Kodi/OSMC media center.
# 
#     This script is the fourth step of configuring the EspressoBin.  It expects
# that the EspressoBin has been configured to boot to MicroSD, it has a MicroSD 
# card with a prevously untouched Ubuntu 16.04 LTS image installed, which has 
# been configured per the instructions at 
# https://github.com/ChameleonGeek/ebin-kodi/README.md
# 
# ==============================================================================
# ==============================================================================

# Colors used for coloring text on screen
BLU='\033[1;34m'
GRN='\033[1;32m'
RED='\033[1;31m'
YEL='\033[1;33m'
NC='\033[0m' # No Color

GetHostName(){
	splash "Give this system a name"
	NEWHOST=$(whiptail --title "HOSTNAME" --inputbox "Enter a name for this system" 8 78 "" 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus = 0 ]; then
		if(whiptail --title "Confirm Host Name" --yesno "You entered $NEWHOST.  Is this correct?" 8 78) then
			echo "$NEWHOST" > /etc/hostname
			echo -e "127.0.0.1\t$NEWHOST" > /etc/hosts
		else
			GetHostName
		fi
	fi
}

GetNewUser(){
	splash "Create user to interact with the EspressoBin"
	NEWUSER=$(whiptail --title "Interactive User" --inputbox "Enter (new) user name to interact with the EspressoBin" 8 78 "" 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus = 0 ]; then
		if(whiptail --title "Confirm User Name" --yesno "You entered $NEWUSER.  Is this correct?" 8 78) then
			splash "Adding User $NEWUSER - Please answer the questions"
			sudo adduser $NEWUSER
			sudo usermod -aG sudo $NEWUSER
			splash "The root user needs password protection"
			sudo passwd root
		else
			GetNewUser
		fi
	fi
}

splash(){
	clear
	echo "${GRN}# =============================================================================="
	echo "# =============================================================================="
	echo "        $1"
	echo "# =============================================================================="
	echo "# ==============================================================================${NC}"
}

SoftwareInstall(){
	if ! [ -e ~/install-complete ]; then
		splash "Adding software sources to enable greater functionality"
		# Adding "universe" sources
		sudo sed -i "s|deb http://ports.ubuntu.com/ubuntu-ports/ xenial main|deb http://ports.ubuntu.com/ubuntu-ports/ xenial main universe|" /etc/apt/sources.list
		
		sudo sed -i "s|deb http://ports.ubuntu.com/ubuntu-ports/ xenial-security main|deb http://ports.ubuntu.com/ubuntu-ports/ xenial-security main universe|" /etc/apt/sources.list

		sudo sed -i "s|deb http://ports.ubuntu.com/ubuntu-ports/ xenial-updates main|deb http://ports.ubuntu.com/ubuntu-ports/ xenial-updates main universe|" /etc/apt/sources.list

		# Setup repo and certificate for webmin
		echo "deb http://download.webmin.com/download/repository sarge contrib" | sudo tee --append /etc/apt/sources.list > /dev/null

		sudo echo "deb http://webmin.mirror.somersettechsolutions.co.uk/repository sarge contrib" | sudo tee --append /etc/apt/sources.list > /dev/null

		sudo wget http://www.webmin.com/jcameron-key.asc -q

		sudo apt-key add jcameron-key.asc
		
		splash "Update and Upgrade"
		sudo apt-get update
		sudo apt-get upgrade -y
			
		splash "Installing utilities"
		sudo apt-get install nano python3-pip tasksel openssh-server -y
		
		# Suggested changes to /etc/ssh/sshd_config:
		# LoginGraceTime 20
		# PermitRootLogin no
		# After Change, restart ssh ??? sudo service ssh restart
		
		splash "Installing LAMP Stack"
		sudo tasksel install lamp-server
		
		splash "Installing OpenSSH Server"
		sudo tasksel install openssh-server
		
		splash "Installing Webmin"
		sudo apt-get install webmin -y
		
		splash "Installing Samba Server"
		sudo tasksel install samba-server
		
		echo "1" > install-complete
	fi
}






# ==============================================================================
# ==============================================================================
#                 Direct the Installation and Configuration
# ==============================================================================
# ==============================================================================
# Install the software
SoftwareInstall
# Create a user other than root with superuser permissions
GetNewUser
# Update EspressoBin hostname to remove "unable to resolve host localhost.localdomain: Connection refused" notices
GetHostName
