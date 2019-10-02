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
# ======================================
#               VARIABLES
# ======================================
# NETWORKING VARIABLES
HOSTNAME="kodiserver"
IP_ADDRESS=""
NET_MASK=""
DNS_SVRS=""
GATEWAY=""

# Domain Controller Variables
DOMAIN_NO_TLD="example"
DOMAIN_TLD=""

USR_INTER=""

# SOFTWARE INSTALLATION FLAGS (0=No, 1=Yes, 2=Done)
INS_LAMP=1     # Linux-Apache-MySQL-PHP Web Server
INS_PHPMA=0    # phpMyAdmin MySQL management
INS_MYSQL=0    # MySQL (Independent of LAMP)
INS_SAMBA=1    # Samba file-sharing services (mandatory for kodi)
INS_SSH=1      # OpenSSH Server (frees EspressoBin from USB tether)
INS_WEBMIN=1   # Webmin web-based server administration tool
INS_DC=0       # Configure as Windows 2008 R2 compatible Domain Controller

# COLORS FOR CLEARER NOTIFICATIONS
BLU='\033[1;34m'
GRN='\033[1;32m'
NC='\033[0m' # No Color
RED='\033[1;31m'
YEL='\033[1;33m'

# ======================================
#   BASIC USER INTERACTION FUNCTIONS
# ======================================
Note(){
	echo "${GRN}$1${NC}"
    
}

Splash(){ # Alerts user of major steps in the configuration process
	# Usage: Splash <display text>
	title="$1"
	clear
	echo "${GRN}=============================================================================="
	echo "=============================================================================="
	printf "%*s\n" $(((${#title}+80)/2)) "$title"
	echo "=============================================================================="
	echo "==============================================================================${NC}"
}

Query(){ # Uses whiptail to ask user for input
    # Usage: Query <default value> <whiptail title> <prompt>
    retval=$(whiptail --title "$2" --inputbox "$3" 8 78 "$1" 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ "$exitstatus" = "0" ]; then
	    echo "$retval"
	else
	    echo ""
	fi
}

YesNo(){ # Uses whiptail to ask yes/no questions
    # Usage: YesNo <whiptail title> <prompt>
    if (whiptail --title "$1" --yesno "$2" 8 78 3>&1 1>&2 2>&3) then
        echo "1"
    else
        echo "0"
    fi
}

varUC(){
	echo "$1" | tr '[a-z]' '[A-Z]'
}

varLC(){
	echo "$1" | tr '[A-Z]' '[a-z]'
}

# ======================================
#         SPECIFIC USER QUERIES
# ======================================
ConfirmDCVars(){
    if [ "$INS_DC" = "0" ]; then return 0; fi
    DOMAIN_NO_TLD=$(varLC "$DOMAIN_NO_TLD")
    DOMAIN_TLD=$(varLC "$DOMAIN_TLD")
    if ! (YesNo "Confirm Domain Name" "You selected ${DOMAIN_NO_TLD}.${DOMAIN_TLD}.\nIs this correct?")
    then
        QueryDCVars
        ConfirmDCVars
    fi
}

QueryDCVars(){
    if [ "$INS_DC" = "0" ]; then return 0; fi
    DOMAIN_NO_TLD=$(Query "$DOMAIN_NO_TLD" "Domain Name" "Enter the Domain Name for the Domain Controller.\nDO NOT include \".com\", \".lan\", etc" 8 78)
    DOMAIN_TLD=$(Query "$DOMAIN_TLD" "Top-Level Domain" "Enter the Top-Level Domain for the Domain Controller (\".com\", \".lan\", etc)" 8 78)
}

ConfirmDNS(){
    if ! (YesNo "Confirm DNS Servers" "You selected $DNS_SVRS as your DNS servers.\nIs this correct?")
    then
        QueryDNS
    fi
}

QueryDNS(){
    tval=$(Query "$DNS_SVRS" "DNS Servers" "Enter your preferred DNS Server address(es).")
    if [ "$tval" = "" ]; then
        QueryDNS
    else
        DNS_SVRS="$tval"
    fi
}

ConfirmGateway(){
    if ! (YesNo "Confirm Gateway/Router IP Address" "You selected $GATEWAY as your default gateway/router.\nIs this correct?")
    then
        QueryGateway
    fi
}

QueryGateway(){
    tval=$(Query "$GATEWAY" "Defult Gateway" "Enter the Gateway/Router IP Address")
    if [ "$tval" = "" ]; then
        QueryGateway
    else
        GATEWAY="$tval"
    fi
}

ConfirmHostname(){
    if ! (YesNo "Confirm Host Name" "You selected \"$HOSTNAME\" as the EspressoBin's Host Name.\nIs this correct?")
    then
        QueryDNS
    fi
}

QueryHostname(){
    tval=$(Query "$HOSTNAME" "Host Name" "Enter the Host Name for the EspressoBin")
    if [ "$tval" = "" ]; then
        QueryHostname
    else
        HOSTNAME=$(varLC "$tval")
    fi
}

ConfirmIPAddr(){
    if ! (YesNo "Confirm IP Address" "You selected $IP_ADDRESS for the EspressoBin IP Address.\nIs this correct?")
    then
        QueryIPAddr
    fi
}

QueryIPAddr(){
    tval=$(Query "$IP_ADDRESS" "IP Address" "Enter the ststic IP address for the EspressoBin")
    if [ "$tval" = "" ]; then
        QueryIPAddr
    else
        IP_ADDRESS="$tval"
    fi
}

ConfirmNetMask(){
    if ! (YesNo "Confirm Network Mask" "You selected $NET_MASK as your network mask.\nIs this correct?")
    then
        QueryNetMask
    fi
}

QueryNetMask(){
    tval=$(Query "$NET_MASK" "Network Mask" "Enter the Network Mask for the network")
    if [ "$tval" = "" ]; then
        QueryNetMask
    else
        NET_MASK="$tval"
    fi
}

ConfirmInstallList(){
    # Determine DNS Status
    if [ "$INS_DC" = "1" ]; then
        prompt="You selected to install Domain Controller.\nThis includes:"
        prompt="${prompt}\n--Kerberos Protocol\n--Bind DNS Server\n--Samba File Sharing\n--LAMP Web-server stack"
        prompt="${prompt}\n--OpenSSH Server\n--Webmin web-based management\n\nIs this correct?"
        if ! (whiptail --title "Confirm Installation Selections" --yesno "${prompt}" 20 78)
        then
            QueryInstallList
            ConfirmInstallList
        fi
    else
        prompt="You selected to install the following:"
        if [ "$INS_SAMBA" = "1" ]; then prompt="${prompt}\n--Samba file-sharing services"; fi
        if [ "$INS_WEBMIN" = "1" ]; then prompt="${prompt}\n--Webmin server management"; fi
        if [ "$INS_LAMP" = "1" ]; then prompt="${prompt}\n--LAMP Web server components"; fi
        if [ "$INS_MYSQL" = "1" ]; then prompt="${prompt}\n--MySQL Database Server"; fi
        if [ "$INS_PHPMA" = "1" ]; then prompt="${prompt}\n--phpMyAdmin"; fi
        if [ "$INS_SSH" = "1" ]; then prompt="${prompt}\n--OpenSSH Server"; fi
        prompt="${prompt}\n\nIs this correct?"
        if ! (whiptail --title "Confirm Installation Selections" --yesno "${prompt}" 14 78)
        then
            QueryInstallList
            ConfirmInstallList
        fi
    fi
}

QueryInstallList(){
    if [ "$INS_SAMBA" = "1" ]; then tSAMBA="ON"; else tSAMBA="OFF"; fi
    if [ "$INS_WEBMIN" = "1" ]; then tWEB="ON"; else tWEB="OFF"; fi
    if [ "$INS_LAMP" = "1" ]; then tLAMP="ON"; else tLAMP="OFF"; fi
    if [ "$INS_MYSQL" = "1" ]; then tSQL="ON"; else tSQL="OFF"; fi
    if [ "$INS_PHPMA" = "1" ]; then tPMA="ON"; else tPMA="OFF"; fi
    if [ "$INS_SSH" = "1" ]; then tSSH="ON"; else tSSH="OFF"; fi
    if [ "$INS_DC" = "1" ]; then tDC="ON"; else tDC="OFF"; fi
    tval=$(whiptail --title "Components" --checklist "Select components to install" 12 78 7 \
        "SAMBA" "Samba file-sharing services" ${tSAMBA} \
        "WEBMIN" "Webmin server management" ${tWEB} \
        "LAMP" "LAMP Web Server" ${tLAMP} \
        "MySQL" "MySQL Server (May be overridden by selecting LAMP)" ${tSQL} \
        "phpMyAdmin" "MySQL Server web-based management" ${tPMA} \
        "SSH" "OpenSSH Server" ${tSSH} \
        "DC" "Domain Controller" ${tDC} \
        3>&1 1>&2 2>&3)
    if [ $(echo "$tval" | grep -o DC) ]; then INS_DC=1; else INS_DC=0; fi
    if [ $(echo "$tval" | grep -o LAMP) ]; then INS_LAMP=1; else INS_LAMP=0; fi
    if [ $(echo "$tval" | grep -o MySQL) ]; then INS_MYSQL=1; else INS_MYSQL=0; fi
    if [ $(echo "$tval" | grep -o SAMBA) ]; then INS_SAMBA=1; else INS_SAMBA=0; fi
    if [ $(echo "$tval" | grep -o SSH) ]; then INS_SSH=1; else INS_SSH=0; fi
    if [ $(echo "$tval" | grep -o WEBMIN) ]; then INS_WEBMIN=1; else INS_WEBMIN=0; fi
    if [ $(echo "$tval" | grep -o phpMyAdmin) ]; then INS_PHPMA=1; else INS_PHPMA=0; fi
}

QueryUserInteractive(){
    tval=$(Query "$USR_INTER" "Interactive Username" "The EspressoBin needs a user other than \"root.\"\nPlease enter this username")
    if [ "$tval" = "" ]; then
        QueryUserInteractive
    else
        USR_INTER=$(varLC "$tval")
    fi
}

ConfirmUserInteractive(){
    if ! (YesNo "Confirm Interactive Username" "You entered $USR_INTER as the interactive username.\nIs this correct?")
    then
        QueryUserInteractive
    fi
}

ConfirmProcess(){
    Splash "Please confirm the settings..."
    sleep 1
    ConfirmHostname
    ConfirmUserInteractive
    ConfirmIPAddr
    ConfirmNetMask
    ConfirmGateway
    ConfirmDNS
    
    ConfirmInstallList
    
    WriteConfigSettings
}

QueryProcess(){
    # PERFORM QUERIES
    QueryHostname
    QueryUserInteractive
    
    QueryInstallList
    
    QueryIPAddr
    QueryNetMask
    QueryGateway
    QueryDNS
    
    QueryDCVars
}

ReadConfigSettings(){
    Note "Loading settings"
    source ebin.conf
    
}

ReadConfigVal(){
    # Reads the configuration/installation settings between reboot
    # Usage: ReadConfigVal <ID String>
	echo "$(grep '${1}' 'ebin.conf' | tail -1 | cut -d':' -f2)"
}

WriteConfigSettings(){
    # This writes all settings to a file so it can be accessed after reboot.
    # Reboot is required for DC configuration.  It is the only way to remedy "unable to resolve host" warnings
    echo "HOSTNAME=$HOSTNAME" > ebin.conf
    echo "IP_ADDRESS=$IP_ADDRESS" >> ebin.conf
    echo "NET_MASK=$NET_MASK" >> ebin.conf
    echo "GATEWAY=$GATEWAY" >> ebin.conf
    echo "DNS_SVRS=$DNS_SVRS" >> ebin.conf

    # DOMAIN SETTINGS (NEEDED FOR DOMAIN CONTROLLER CONFIG)
    echo "DOMAIN_NO_TLD=$DOMAIN_NO_TLD" >> ebin.conf
    echo "DOMAIN_TLD=$DOMAIN_TLD" >> ebin.conf
    
    # INTERACTIVE USER
    echo "USR_INTER=$USR_INTER" >> ebin.conf
    
    # INSTALLATION SELECTIONS
    echo "INS_LAMP=$INS_LAMP" >> ebin.conf
    echo "INS_MYSQL=$INS_MYSQL" >> ebin.conf
    echo "INS_SAMBA=$INS_SAMBA" >> ebin.conf
    echo "INS_SSH=$INS_SSH" >> ebin.conf
    echo "INS_WEBMIN=$INS_WEBMIN" >> ebin.conf
    echo "INS_DC=$INS_DC" >> ebin.conf
    echo "INS_PHPMA=$INS_PHPMA" >> ebin.conf

}

# ======================================
#          READ CURRENT SETTINGS
# ======================================
LoadBaseNetSettings(){
    HOSTNAME="$(hostname | tail -1 | cut -d'.' -f1)"
    IP_ADDRESS="$(ifconfig | grep -A 1 'lan1' | tail -1 | cut -d ':' -f 2 | cut -d ' ' -f 1)"
    NET_MASK="$(ifconfig lan1 | grep Mask | cut -d":" -f4)"
    GATEWAY="$(ip route | grep 'default' | cut -d" " -f3)"
    DNS_SVRS="$(grep nameserver /etc/resolv.conf | cut -d" " -f2)"
}

# ======================================
#         INSTALLATION FUNCTIONS
# ======================================
insBaseUtils(){
    # Install various software independent of primary configuration selections.  Separated as a function to permit additional steps if desired
	echo "wget" >> installed.list
    Note "Installing some necessary tools"
    
    Note "Installing source"
    apt-get install source -y
	echo "source" >> installed.list
    
    Note "Installing nano text editor"
    apt-get install nano -y
	echo "nano" >> installed.list
    
    Note "Installing pip for Python3"
    apt-get install python3-pip -y
	echo "python3-pip" >> installed.list
    
    Note "Installing tasksel"
    apt-get install tasksel -y
	echo "tasksel" >> installed.list

    Note "Basic tools installed"
}

insMain(){
    # Main installation controller
    ReadConfigSettings # banging on this due to dropped IP config
    
    Note "Beginning the installation of selected software."
    if [ "$INS_SSH" = "1" ]; then
        Note "Installing OpenSSH Server"
		tasksel install openssh-server
		echo "OpenSSH Server" >> installed.list
    fi
    
    if [ "$INS_MYSQL" = "1" ] && [ "$INS_LAMP" = "0" ]; then
        Note "Installing MySQL Server"
        apt-get install mysql-server -y
        Note "Securing MySQL Server"
        mysql_secure_installation utility
		echo "MySQL Server" >> installed.list
    fi
    
    if [ "$INS_LAMP" = "1" ]; then
        Note "Installing LAMP Components"
		tasksel install lamp-server
		echo "LAMP Server" >> installed.list
    fi

    if [ "$INS_WEBMIN" = "1" ]; then
        Note "Installing Webmin"
		apt-get install webmin -y
		echo "Webmin" >> installed.list
    fi

    if [ "$INS_PHPMA" = "1" ] && [ "$INS_LAMP" = "1" ] ; then
        Note "Installing phpMyAdmin"
		apt-get install phpmyadmin php-mbstring php-gettext -y
		Note "Reinforcing phpMyAdmin Security"
		phpenmod mcrypt
		phpenmod mbstring
        Note "Restarting Apache webserver"
		systemctl restart apache2
		echo "phpMyAdmin" >> installed.list
    fi
    
    if [ "$INS_SAMBA" = "1" ] && [ "$INS_DC" = "0" ]; then
        Note "Installing Samba FileServer"
        tasksel install samba-server
		echo "Samba" >> installed.list
    fi
    
    if [ "$INS_DC" = "1" ]; then
        Note "Installing Domain Controller Components"
    fi
}

insUpdate(){
    # Updates package lists and some software.  Separated as a function to permit additional steps if desired
    Note "Executing apt-get update"
    apt-get update
}

insUpgrade(){ 
    # Performs upgrade of Ubuntu and installed programs.  Separated as a function to permit additional steps if desired
    Note "Executing apt-get upgrade"
    apt-get upgrade -y
}

netConfig(){
    # Makes network configuration permanent
    ReadConfigSettings # banging on this due to dropped IP config

    Note "Setting up static networking"
    echo 'auto eth0' > /etc/network/interfaces
    echo 'iface eth0 inet manual' >> /etc/network/interfaces
    echo '' >> /etc/network/interfaces
    echo 'auto lo' >> /etc/network/interfaces
    echo 'iface lo inet loopback' >> /etc/network/interfaces
    echo '' >> /etc/network/interfaces
    echo 'auto lan1' >> /etc/network/interfaces
    echo 'iface lan1 inet static' >> /etc/network/interfaces
    Note "IP Address: $IP_ADDRESS"
    echo "\taddress $IP_ADDRESS" >> /etc/network/interfaces
    Note "Network Mask: $NET_MASK"
    echo "\tnetmask $NET_MASK" >> /etc/network/interfaces
    Note "Default Gateway: $GATEWAY"
    echo "\tgateway $GATEWAY" >> /etc/network/interfaces
    Note "DNS Servers: $DNS_SVRS"
    echo "\tdns-nameservers $DNS_SVRS" >> /etc/network/interfaces
    echo '' >> /etc/network/interfaces
    echo 'pre-up /sbin/ifconfig lan1 up' >> /etc/network/interfaces
    echo 'pre-up /sbin/ifconfig eth0 up' >> /etc/network/interfaces
}

OnlineCheck(){
    echo $(ping -q -w1 -c1 google.com &>/dev/null && echo 1 || echo 0)
}

tempNet(){
	Note "Performing temporary network setup (DHCP).  This will take a moment."
	ip link set dev eth0 up
	ip link set dev lan1 up
	dhclient lan1
	Note "Restarting Networking."
	/etc/init.d/networking restart
	Note "Checking if EspressoBin is on line."
	ping -c 3 github.com
	if [ "$(OnlineCheck)" = "1" ]; then
	    Note "System is online"
	else
	    Note "System is offline"
	fi
}

updHost(){
	Note "Updating Host Name."
    echo "$HOSTNAME" > /etc/hostname
    echo "127.0.0.1\t$HOSTNAME" > /etc/hosts
    if ! [ "$DOMAIN_TLD" = "" ]; then
        echo "127.0.0.1\t$HOSTNAME.$DOMAIN_NO_TLD.$DOMAIN_TLD" > /etc/hosts
    fi
}

updRepos(){
    # Updates repositories to allow a wider set of software than is supported by EspressoBin base Ubuntu install
	# ADD UNIVERSE SOURCES
	Note "Updating Repositories."
	sed -i 's| xenial main| xenial main universe|' /etc/apt/sources.list
	sed -i 's| xenial-security main| xenial-security main universe|' /etc/apt/sources.list
	sed -i 's| xenial-updates main| xenial-updates main universe|' /etc/apt/sources.list
	sed -i 's| universe universe| universe|' /etc/apt/sources.list
	
	# ADD WEBMIN SOURCES IF APPROPRIATE
	if [ $INS_WEBMIN = 0 ]; then return 0; fi
	Note "Adding Webmin repositories"
	found=$(grep "download.webmin.com" /etc/apt/sources.list)
	if [ "$found" = "" ]; then
	    echo "deb http://download.webmin.com/download/repository sarge contrib" >> /etc/apt/sources.list
    fi
    found=$(grep "webmin.mirror" /etc/apt/sources.list)
    if [ "$found" = "" ]; then
		echo "deb http://webmin.mirror.somersettechsolutions.co.uk/repository sarge contrib" >> /etc/apt/sources.list
	fi
	
	Note "Adding key for Webmin"
	# ADD WEBMIN KEYS
	wget http://www.webmin.com/jcameron-key.asc -q
	apt-key add jcameron-key.asc
	apt-key update
	
	# IMPLEMENT THE REPO UPDATES
    insUpdate   
}

UserUpdate(){
    Note "User \"root\" needs a password"
    passwd root
    
    Note "Adding Interactive User \"$USR_INTER\""
    adduser ${USR_INTER}
	usermod -aG sudo ${USR_INTER}
	
	if [ "$INS_SAMBA" = "1" ] || [ "$INS_DC" = "1" ]; then
	    Note "This user ($USR_INTER) should be added to Samba."
	    smbpasswd -a ${USR_INTER}
	fi
}

SecondRun(){
    # Will not run if the script hasn't run yet, which means that the script has to run and collect the configuration settings
    if ! [ -e 'ebin.conf' ]; then return 0; fi
    Splash "EspressoBin Configuration: Part 2 - Software installation and configuration"
    sleep 1
    if ! [ "$(YesNo "EspressoBin Config part 2" "Finalize the configuration?")" = "1" ]; then exit; fi
    
    tempNet
    insBaseUtils
    ReadConfigSettings
    insMain
    netConfig
    UserUpdate
    
    rm /etc/profile.d/ebin.sh
    #rm ebin.conf
    #rm -- "$0"
}

FirstRun(){
    # Should only run once.  Collects configuration settings, performs initial configuration and updates
    # Reboots the EspressoBin to set hotsname
    if [ -e 'ebin.conf' ]; then return 0; fi
    Splash "EspressoBin Configuration: Initial Config Options"
    sleep 1
    
    LoadBaseNetSettings
    QueryProcess
    ConfirmProcess
    Splash "Updating Software Sources"
    updRepos

    insUpgrade
    
    updHost
    
	dpkg-reconfigure tzdata

    echo "#!/bin/bash" > /etc/profile.d/ebin.sh
    echo "sh /root/ebin-kodi.s" >> /etc/profile.d/ebin.sh
    chmod +x /etc/profile.d/ebin.sh
    
    if (YesNo "Part 1 Complete" "The EspressoBin needs to reboot.\nThe configuration will resume as soon as you log in after reboot and log in."); then reboot; fi
}

echo "if [ -e ebin-kodi.s ]; then; rm ebin-kodi.s; fi" > redux.sh
echo "wget chameleonoriginals.com/c/ebin-kodi.s" >> redux.sh
echo "chmod +x ebin-kodi.sh" >> redux.sh
echo "sh ebin-kodi.sh" >> redux.sh

SecondRun
FirstRun


