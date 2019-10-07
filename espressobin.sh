#!/bin/bash
# ==============================================================================
# ==============================================================================
# 
#                               EspressoBin Config
#                             Kodi/OSMC Media Server
#                                September, 2019
#                   https://github.com/ChameleonGeek/ebin-kodi
# 
#	 This script performs the basic software installation and configuration 
# necessary to make a new EspressoBin v7 into an Ubuntu 16.04 LTS server with 
# various software necessary to support a Kodi/OSMC media center.
# 
#	 This script is the fourth step of configuring the EspressoBin.  It expects
# that the EspressoBin has been configured to boot to MicroSD, it has a MicroSD 
# card with a prevously untouched Ubuntu 16.04 LTS image installed, which has 
# been configured per the instructions at 
# https://github.com/ChameleonGeek/ebin-kodi/README.md
# 
# ==============================================================================
# ==============================================================================

# ==========================================================
#                                                  VARIABLES
# ==========================================================
BLU='\033[1;34m'   # Makes on-screen text blue
CYA='\033[1;36m'   # Makes on-screen text cyan
GRN='\033[1;32m'   # Makes on-screen text green
MAG='\033[1;35m'   # Makes on-screen text magenta
NC='\033[0m'	   # Makes on-screen text default (white)
RED='\033[1;31m'   # Makes on-screen text red
YEL='\033[1;33m'   # Makes on-screen text yellow


# ==========================================================
#                                           MANAGE VARIABLES
# ==========================================================
sed_escape() {
  sed -e 's/[]\/$*.^[]/\\&/g'
}

cfg_write() { # key, value
  cfg_delete "$1"
  echo "$1=$2" >> "cfginfo.cfg"
}

cfg_read() { # key -> value
  test -f "cfginfo.cfg" && grep "^$(echo "$1" | sed_escape)=" "cfginfo.cfg" | sed "s/^$(echo "$1" | sed_escape)=//" | tail -1
}

cfg_delete() { # key
  test -f "cfginfo.cfg" && sed -i "/^$(echo $1 | sed_escape).*$/d" "cfginfo.cfg"
}

cfg_haskey() { # key
  test -f "cfginfo.cfg" && grep "^$(echo "$1" | sed_escape)=" "cfginfo.cfg" > /dev/null
}

varUC(){
	echo "$1" | tr '[a-z]' '[A-Z]'
}

varLC(){
	echo "$1" | tr '[A-Z]' '[a-z]'
}

# ==========================================================
#                             IPV4 NETWORK ADDRESS FUNCTIONS
# ==========================================================
ip2int(){
	local a b c d
	{ IFS=. read a b c d; } <<< $1
	echo $(((((((a << 8) | b) << 8) | c) << 8) | d))
}

int2ip(){
	local ui32=$1; shift
	local ip n
	for n in 1 2 3 4; do
		ip=$((ui32 & 0xff))${ip:+.}$ip
		ui32=$((ui32 >> 8))
	done
	echo $ip
}

netmask(){
	local mask=$((0xffffffff << (32 - $1))); shift
	int2ip $mask
}

broadcast(){
	local addr=$(ip2int $1); shift
	local mask=$((0xffffffff << (32 -$1))); shift
	int2ip $((addr | ~mask))
}

network(){
	local addr=$(ip2int $1); shift
	local mask=$((0xffffffff << (32 -$1))); shift
	int2ip $((addr & mask))
}

# ==========================================================
#                                   USER INTERFACE FUNCTIONS
# ==========================================================
alert(){ echocolor "${RED}" "$1"; }

echocolor() { echo -e "$1$2${NC}"; }

note(){ echocolor "${GRN}" "$1"; }

queryconfirm(){
	# Usage:  <default value> <title> <prompt> <config key>
	ret="$(querystring "$1" "$2" "$3")"
	ci="0"
	while [ "$ci" = "0" ]; do
		ret="$(yesno "Install $1?"  "Do you want to install $1?")"
		if [ "$ret" = "1" ]; then
			ci="$(yesno "Confirm Install" "You chose to install $1. Is this correct?")"
		else
			ci="$(yesno "Confirm Install" "You chose NOT to install $1. Is this correct?")"
		fi
	done
}

querystring(){
	# Usage: Query <default value> <whiptail title> <prompt>
	retval=$(whiptail --title "$2" --inputbox "$3" 8 78 "$1" 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ "$exitstatus" = "0" ]; then
		echo "$retval"
	else
		echo ""
	fi
}

yesno(){
	# Uses whiptail to ask user yes/no questions
	if (whiptail --title "$1" --yesno "$2" 8 78 3>&1 1>&2 2>&3) then
		echo "1"
	else
		echo "0"
	fi
}

yesnoconfirm(){
	# Usage: appname
	ret="$(yesno "Install $1?"  "Do you want to install $1?")"
	if [ "$ret" = "1" ]; then
		ret="$(yesno "Confirm Install" "You chose to install $1. Is this correct?")"
	else
		ret="$(yesno "Confirm Install" "You chose NOT to install $1. Is this correct?")"
	fi
	echo "$ret"
}

yesnoinstall(){
	# Usage: appname
	ci="0"
	while [ "$ci" = "0" ]; do
		ret="$(yesno "Install $1?"  "Do you want to install $1?")"
		if [ "$ret" = "1" ]; then
			ci="$(yesno "Confirm Install" "You chose to install $1. Is this correct?")"
		else
			ci="$(yesno "Confirm Install" "You chose NOT to install $1. Is this correct?")"
		fi
	done
	
	cfg_write "$2" "$ret"
}
# ==========================================================
#                                    ALTER AND TEST SETTINGS
# ==========================================================
dhcpnetstart(){
	note "Performing temporary network setup (DHCP).  This will take a moment."
	ip link set dev eth0 up
	ip link set dev lan1 up
	dhclient lan1
	if [ "$(onlinecheck)" ]; then
		note "System is online"
	else
		note "System is offline"
	fi
}

killfirst(){
	# Remove the script which makes this script run on login,
	# which was created on the first run of this script.
	if ! [ -e "/etc/profile.d/ebin.sh" ]; then
		rm /etc/profile.d/ebin.sh
	fi
}

onlinecheck(){
	note "Checking if EspressoBin is on line."
	res="$(ping -q -w1 -c1 github.com &>/dev/null && echo 1 || echo 0)"
	if [ "$res" = "1" ]; then
		note "System is online"
	else
		alert "System is offline"
	fi
	return $res
}

sethostname(){
	note "Setting Host Name"
	HOSTNAME="$(cfg_read HOSTNAME)"
	hostname -b "$HOSTNAME"
	echo "$HOSTNAME" > /etc/hostname
	echo -e "127.0.0.1\t$HOSTNAME" > /etc/hosts
	fulldom="$(cfg_read "Domain Name")"
	if ! [ "$fulldom" = "" ]; then
		echo "127.0.0.1\t$HOSTNAME.$fulldom" > /etc/hosts
	else
		echo "127.0.0.1\t$HOSTNAME.$fulldom $HOSTNAME" > /etc/hosts
	fi
	hostname -b "$HOSTNAME"
	/etc/init.d/hostname.sh restart
}

setipconfig(){	note "Setting up static networking for testing"
	echo 'auto eth0' > /etc/network/interfaces
	echo 'iface eth0 inet manual' >> /etc/network/interfaces
	echo '' >> /etc/network/interfaces
	echo 'auto lo' >> /etc/network/interfaces
	echo 'iface lo inet loopback' >> /etc/network/interfaces
	echo '' >> /etc/network/interfaces
	echo 'auto lan1' >> /etc/network/interfaces
	echo 'iface lan1 inet static' >> /etc/network/interfaces
	echo -e "\taddress $(cfg_read "IP Address")" >> /etc/network/interfaces
	echo -e "\tnetmask $(cfg_read "Network Mask")" >> /etc/network/interfaces
	echo -e "\tgateway $(cfg_read "Default Gateway")" >> /etc/network/interfaces
	echo -e "\tdns-nameservers $(cfg_read "DNS Servers")" >> /etc/network/interfaces
	echo '' >> /etc/network/interfaces
	echo 'pre-up /sbin/ifconfig lan1 up' >> /etc/network/interfaces
	
	ip addr flush lan1
	systemctl restart networking.service
	echo "1"
}

setsources(){
	# Updates repositories to allow a wider set of software than is supported by 
	# EspressoBin base Ubuntu install
	# ADD UNIVERSE SOURCES
	note "Updating Repositories."
	sed -i 's| xenial main| xenial main universe|' /etc/apt/sources.list
	sed -i 's| xenial-security main| xenial-security main universe|' /etc/apt/sources.list
	sed -i 's| xenial-updates main| xenial-updates main universe|' /etc/apt/sources.list
	sed -i 's| universe universe| universe|' /etc/apt/sources.list
	
	note "Updating package lists"
	apt-get update
}

setwebminsources(){
	# ADD WEBMIN REPOS IF NECESSARY
	if [ "$(cfg_read WEBMIN)" = "0" ]; then return 0; fi
	note "Adding Webmin repositories"
	found=$(grep "download.webmin.com" /etc/apt/sources.list)
	if [ "$found" = "" ]; then
		echo "deb http://download.webmin.com/download/repository sarge contrib" >> /etc/apt/sources.list
	fi
	found=$(grep "webmin.mirror" /etc/apt/sources.list)
	if [ "$found" = "" ]; then
		echo "deb http://webmin.mirror.somersettechsolutions.co.uk/repository sarge contrib" >> /etc/apt/sources.list
	fi
	
	note "Adding key for Webmin"
	# ADD WEBMIN KEYS
	wget http://www.webmin.com/jcameron-key.asc -q
	apt-key add jcameron-key.asc

	note "Updating package lists"
	apt-get update
}

# ==========================================================
#                                                 INSTALLERS
# ==========================================================
loginstall(){ echo "$1" >> installed.list; }

installftp(){
	if ! [ "$(cfg_read PROFTPD)" = "0" ]; then return 0; fi
	apt-get install proftpd -y
	loginstall "ProFTPD Server"
}

installlamp(){
	if [ "$(cfg_read LAMP)" = "0" ]; then return 0; fi
	note "Installing LAMP web server"
	tasksel install lamp-server
	ipaddr="$(cfg_read 'IP Address')"
	echo "ServerName $ipaddr" >> /etc/apache2/apache2.conf
	note "Restarting Apache"
	systemctl restart apache2
	loginstall "LAMP Server"
}

installmysql(){
	if [ "$(cfg_read MYSQL)" = "0" ]; then return 0; fi
	note "Installing MySQL Server"
	apt-get install mysql-server -y
	loginstall "MySQL Server"
}

installnano(){
	note "Installing nano text editor"
	apt-get install nano -y
	loginstall "nano"
}

installopenvpn(){
	if [ "$(cfg_read OPENVPN)" = "0" ]; then return 0; fi
	note "Installing OpenVPN Server"
	apt-get install openvpn easy-rsa -y
	# TODO:: Additional steps to secure and configure?	
	loginstall "OpenVPN"
}

installphpmyadmin(){
	if ! [ "$(cfg_read PHPMYADMIN)" = "1" ] || ! [ "$(cfg_read LAMP)" = "1" ]; then return 0; fi
	note "Installing phpMyAdmin"
	apt-get install phpmyadmin php-mbstring php-gettext -y 
	note "Reinforcing phpMyAdmin Security"
	phpenmod mcrypt
	phpenmod mbstring
	note "Restarting Apache webserver"
	systemctl restart apache2
	loginstall "phpMyAdmin"
}

installpip(){ 
	note "Installing pip for Python3"
	apt-get install python3-pip -y
	loginstall "python3-pip"
}

installsamba(){
	if [ "$(cfg_read SAMBA)" = "0" ]; then return 0; fi
	note "Installing Samba FileServer"
	tasksel install samba-server
	loginstall "Samba"
}

installssh(){
	if [ "$(cfg_read SAMBA)" = "0" ]; then return 0; fi
	note "Installing OpenSSH Server"
	apt-get install openssh-server -y
	loginstall "OpenSSH"
}

installtasksel(){
	note "Installing tasksel" 
	apt-get install tasksel -y
	loginstall "tasksel"
}

installwebmin(){
	if ! [ "$(cfg_read WEBMIN)" = "1" ]; then return 0; fi
	note "Installing webmin"
	setwebminsources
	apt-get install webmin -y
	loginstall "Webmin"
}

# ==========================================================
#                                       INSTALLATION PROMPTS
# ==========================================================
queryinstalltype(){
	ret="$(whiptail --title "CONFIGURATION TYPE" --radiolist "Select the configuration type:" \
	12 78 5 \
	"Basic Configuration" "Minimal configuration and installation" OFF \
	"File Server" "Samba file server with Webmin server manager" ON \
	"Custom Configuration" "Select components to install" OFF \
	3>&1 1>&2 2>&3)"
	cfg_write "INSTALL" "$ret"
	
	
	prompt="You selected $ret.  Is this correct?"
	if [ "$(yesno "Confirm Configuration Type" "$prompt")" = "0" ]; then
		queryinstalltype
	fi
	
	querysubinstall
}

querylamp(){
	yesnoinstall "LAMP Web Server Stack" "LAMP"
	if [ "$(cfg_read "LAMP")" = "1" ]; then
		yesnoinstall "phpMyAdmin mySQL management" "PHPMYADMIN"
	fi
}

queryftp(){ yesnoinstall "ProFTPD FTP Server" "PROFTPD"; }

querymysql(){
	yesnoinstall "mySQL Database Server" "MYSQL"
	if [ "$(cfg_read "MYSQL")" = "1" ]; then
		yesnoinstall "phpMyAdmin mySQL management" "PHPMYADMIN"
	fi
}

querysamba(){ yesnoinstall "Samba File Server" "SAMBA"; }

queryssh(){ yesnoinstall "OpenSSH" "OPENSSH"; }

querysubinstall(){
	#note "querysubinstall"
	case "$(cfg_read "INSTALL")" in
		"Basic Configuration")
			querywebmin
			;;
		"File Server")
			cfg_write "SAMBA" "1"
			querywebmin
			queryssh
			;;
		"Domain Controller")
			cfg_write "LAMP" "1"
			cfg_write "PHPMYADMIN" "1"
			#cfg_write "PROFTPD" "1"
			cfg_write "OPENSSH" "1"
			cfg_write "OPENVPN" "1"
			cfg_write "WEBMIN" "1"
			;;
		"Custom Configuration")
			querywebmin
			queryssh
			queryvpn
			querylamp
			if [ "$(cfg_read "LAMP")" = "0" ]; then querymysql; fi
			querysamba
			;;
		*)
			alert "Configuration selection failed"
			exit
			;;
	esac
}

queryvpn(){ yesnoinstall "OpenVPN Server" "OPENVPN"; }

querywebmin(){ yesnoinstall "Webmin server management" "WEBMIN"; }

# ==========================================================
#                                      CONFIGURATION PROMPTS
# ==========================================================
queryconfigdata(){
	note "Collecting system settings"

	queryhostname
	queryipbase
	cfg_write "Interactive User" "$(querystringconfirm "" "Interactive User" "This system needs an interactive user other than root.  Enter a new user name.")"
	
	if ! [ "$(cfg_read "INSTALL")" = "Domain Controller" ]; then return 0; fi
	cfg_write "Domain Name" "$(querydomainfull)"
}

queryipbase(){
	IP_ADDRESS="$(ifconfig | grep -A 1 'lan1' | tail -1 | cut -d ':' -f 2 | cut -d ' ' -f 1)"
	NET_MASK="$(ifconfig lan1 | grep Mask | cut -d":" -f4)"
	GATEWAY="$(ip route | grep 'default' | cut -d" " -f3)"
	DNS_SVRS="$(grep nameserver /etc/resolv.conf | cut -d" " -f2)"

	cfg_write "IP Address" "$(queryipconfig "$IP_ADDRESS" "IP Address" "Enter the static IP Address for this system.")"
	cfg_write "Network Mask" "$(queryipconfig "$NET_MASK" "Network Mask" "Enter the Network Mask for this system.")"
	cfg_write "Default Gateway" "$(queryipconfig "$GATEWAY" "Default Gateway" "Enter the Default Gateway for this system.")"
	cfg_write "DNS Servers" "$(queryipconfig "$DNS_SVRS" "DNS Servers" "Enter the preferred DNS Server(s) for this system.")"
}

querydomainfull(){
	retval=""
	while [ "$retval" = "" ]; do
		retval="$(querystringconfirm "" "Full Domain Name" "Enter the full domain name this DC will control (such as example.lan)")"

		# Validate domain.tld entered
		IFS='.' read -r -a DOMSET <<< "$retval"
		if ! [ "${#DOMSET[@]}" = "2" ]; then querydomainfull; fi
	done
	echo "$retval"
}

queryipconfig(){
	retval=""
	while [ "$retval" = "" ]; do
		retval="$(querystring "$1" "$2" "$3")"
		if [ "$(yesno "Confirm $2" "You entered \"$retval\". Is this correct?")" = "0" ]; then
			querystringconfirm "$1" "$2" "$3"
		fi
		
		# Verify that address is 4 octets long and 0 =< each =< 255
		IFS='.' read -r -a ADDROCT <<< "$retval"
		if ! [ "${#ADDROCT[@]}" == 4 ]; then
			# Wrong number of octets
			echo "${#ADDROCT[@]}, rather than 4 octets provided"
			queryipconfig
		else
			for element in "${ADDROCT[@]}"; do
				if [ $element -lt 0 -o $element -gt 255 ]; then
					echo "All octets must be 0 =< x =< 255"
					queryipconfig
				fi
			done
		fi
	done
	echo "$retval"
}

querystringconfirm(){ # <default value> <whiptail title> <prompt>
	retval=""
	while [ "$retval" = "" ]; do
		retval="$(querystring "$1" "$2" "$3")"
		if [ "$(yesno "Confirm $2" "You entered \"$retval\" Is this correct?")" = "0" ]; then
			querystringconfirm "$1" "$2" "$3"
		fi
	done
	echo "$retval"
}

queryhostname(){ # <default value> <whiptail title> <prompt>
	cfg_write "HOSTNAME" "$(querystringconfirm "$(hostname)" "Host Name" "Enter the Host Name for this system")"
}
# ==========================================================
#                         INSTALL REQUIRED/SELECTED PROGRAMS
# ==========================================================
navinstallation(){
	sethostname
	setipconfig
	note "Updating Time Zone"
	dpkg-reconfigure tzdata
	case "$(cfg_read "INSTALL")" in
		"Basic Configuration")
			perfinstallbasic
			;;
		"Custom Configuration")
			perfinstallcustom
			;;
		"File Server")
			perfinstallfilesvr
			;;
	esac
	
	note "Upgrading Ubuntu Minimal"
	apt-get upgrade ubuntu-minimal -y
	
	userupdates
}

netconfig(){
	note "Executing netconfig"
	while [ "$(setipconfig)" = "0" ]; do
		queryipbase
	done
	#while [ "$retval" = "" ]; do
}

perfupgrade(){
	note "Upgrading from Ubuntu minimal install"
	apt-get upgrade -y
}

perfinstallrequired(){
	note "Installing preliminary software"
	setsources
	perfupgrade
	installnano
	installpip
	installtasksel
}

perfinstallbasic(){
	note "Performing software installation: Basic Install"
	perfinstallrequired
	installwebmin
}

perfinstallcustom(){
	note "Performing software installation: Custom Install"
	perfinstallrequired
	installsamba
	installlamp
	installmysql
	installphpmyadmin
	installftp
	installssh
	installopenvpn	
	installwebmin
}

perfinstallfilesvr(){
	note "Performing software installation: File Server Install"
	perfinstallrequired
	installssh
	installftp
	installsamba
	installwebmin
}

userupdates(){
	note "User \"root\" needs a password"
	passwd root
	
	newuser="$(cfg_read "Interactive User")"
	note "Adding Interactive User \"$newuser\""
	adduser ${newuser}
	usermod -aG sudo ${newuser}
	
	if [ "$(cfg_read "SAMBA")" = "1" ]; then
		note "The user ($newuser) should be added to Samba."
		smbpasswd -a ${newuser}

	fi

}
# ==========================================================
#                                            EXEC NAVIGATION
# ==========================================================

firstrun(){
	if [ -e cfginfo.cfg ]; then return 0; fi
	# temporarily setting hostname to stop hostname resoluton warnings
	note "Starting configuration script"
	cfg_write "HOSTNAME" "kodiserver"
	note "Starting network (DHCP).  This will take a moment"
	dhcpnetstart # Start networking
	sethostname
	queryinstalltype
	queryconfigdata
	navinstallation
	note "Installation and configuration is complete."
	rm cfginfo.cfg
	rm installed.list
	rm "$0"
}

firstrun
