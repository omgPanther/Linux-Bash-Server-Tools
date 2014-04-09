#!/bin/bash

### Server Edit

# Old IP
OldIP=$(ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{print $1}')

_SCRIPTPATHNAME="$(readlink -f ${BASH_SOURCE[0]})" # Script Path/Name
_SCRIPTPATH="$(dirname $_SCRIPTPATHNAME)/"         # Script Path
_CURRENTDIR="$PWD/"                                # Current DIR

# Logfile path
logfile=$_SCRIPTPATH"serveredit.log"

# Default date
dDate=$(date +"%a %b %d %Y %I:%M:%S%P")

# REGEX
regex="(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)"

#log function
log() {
        message=$1
        logtype=$2
        echo '['$dDate'] ['$logtype'] ['$USER'] - '$message >>$logfile
}

# Vailid IP Function
valid_ip(){
	local  ip=$1
	local  stat=1
	if [[ $ip =~ $regex ]]
	then
		stat=0
	else
		stat=1
	fi
	return $stat
}

# confirm function
confirm() {
	read -p "Confirm change of IP to "$1" ? [y/N]" response
	if [[ $response =~ ^(Y|y| ) ]]
	then
		stat=0
	else
		stat=1
	fi

	return $stat
}

# Ask for new IP
read -p 'Change IPs to: ' newip

# check IP address
if valid_ip $newip
then
	# confirm IP change
	if confirm $newip
	then
        	echo 'IP changed.'
        	log 'IPs changed to: '$newip 'IP CHANGE'
		# read file
		sed -i.bak "s/$OldIP/$newip/g" $logfile
		exit 0
	else
        	echo 'cancled'
		exit 0
	fi
else
	echo "Invalid IP"
	exit 0
fi

# exit
exit 0
