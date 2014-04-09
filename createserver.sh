#!/bin/bash

#--------------[ TEXT ]----------------
txtbold=$(tput bold)        # bold
txtund=$(tput sgr 0 1)      # Underline
txtred=$(tput setaf 1)      # Red
txtgreen=$(tput setaf 2)    # Green
txtyellow=$(tput setaf 3)   # Yellow
txtblue=$(tput setaf 4)     # Blue
txtpurple=$(tput setaf 5)   # Purple
txtcyan=$(tput setaf 6)     # Cyan
txtwhite=$(tput setaf 7)    # White
txtreset=$(tput sgr0)       # Reset
column=`tput cols`
column=$(($column-7))
#--------------------------------------

#------------------------[ Variables ]-------------------------------
declare -A varArray
varArray[SCRIPTNAME]="$(basename $0)"
varArray[SCRIPTPATHNAME]="$(readlink -f ${BASH_SOURCE[0]})"
varArray[SCRIPTPATH]="$(dirname $(readlink -f ${BASH_SOURCE[0]}))"
varArray[CURRENTDIR]="$PWD"
varArray[INCLUDESPATH]="$(dirname $(readlink -f ${BASH_SOURCE[0]}))/includes"
varArray[BINDPATH]="/etc/bind"
varArray[ZONEFILEPATH]="/etc/bind/zones"
varArray[SITESAVAILABLEPATH]="/etc/apache2/sites-available"
varArray[SERVERIP]=$(ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{print $1}')
varArray[DDATE]=$(date +"%a %b %d %Y %I:%M:%S%P")
varArray[LOGFILE]="$(dirname $(readlink -f ${BASH_SOURCE[0]}))/createserver.log"

DefaultDir=("public_html" "public_html/css" "public_html/images" "public_html/js")
SmartyDir=("templates" "templates_c" "configs" "cache" "public_html" "public_html/css" "public_html/images" "public_html/js")

#--------------------------------------------------------------------

# Clear Screen
clear

# Make Sure Text Is Reset Before We Begin
echo $txtreset

# Check for Arguments
if [ -n "$1" ]
then
	case "$1" in
		"-d")
			echo $txtwhite"---------------------------------------[ Variables ]---------------------------------------"
			for i in "${!varArray[@]}"
			do
				if [ "$i" = "IpReg" ]
				then
				echo -e $txtwhite"[ "$txtred"$i"$txtwhite" ]^ : "$txtyellow"To long to list (xxx.xxx.xxx.xxx)"
			else
				echo -e $txtwhite"[ "$txtred"$i"$txtwhite" ]^ : "$txtyellow"${varArray[$i]}"
			fi
			done | column -t -s"^"
			echo $txtwhite"-------------------------------------------------------------------------------------------"$txtreset
			echo
			echo $txtwhite"---------------------------------------[ Functions ]---------------------------------------"
			echo -e $txtwhite"Valid IP ............ [ "$txtred"valid_ip()"$txtwhite" ]       : "$txtyellow"Checks to be sure IP is valid"
			echo -e $txtwhite"Log ................. [ "$txtred"log()"$txtwhite" ]            : "$txtyellow"[\$dDate] [\$logtype] [\$USER] - \$message >>\$LogFile"
			echo $txtwhite"-------------------------------------------------------------------------------------------"$txtreset
			echo
			;;
		"-l")
			echo $txtwhite"---------------------------------------[ Variables ]---------------------------------------"
			for i in "${!varArray[@]}"
			do
				if [ "$i" = "IpReg" ]
				then
					echo -e $txtwhite"[ "$txtred"$i"$txtwhite" ]^ : "$txtyellow"To long to list (xxx.xxx.xxx.xxx)"
				else
					echo -e $txtwhite"[ "$txtred"$i"$txtwhite" ]^ : "$txtyellow"${varArray[$i]}"
				fi
			done | column -t -s"^"
			echo $txtwhite"-------------------------------------------------------------------------------------------"$txtreset
			echo
			echo $txtwhite"---------------------------------------[ Functions ]---------------------------------------"
			echo -e $txtwhite"Valid IP ............ [ "$txtred"valid_ip()"$txtwhite" ]       : "$txtyellow"Checks to be sure IP is valid"
			echo -e $txtwhite"Log ................. [ "$txtred"log()"$txtwhite" ]            : "$txtyellow"[\$dDate] [\$logtype] [\$USER] - \$message >>\$LogFile"
			echo $txtwhite"-------------------------------------------------------------------------------------------"$txtreset
			echo
			exit 0
			;;
		*)
			echo -e $txtred"Only '-d' is used! (Debug), Aborting!"$txtreset
			exit 1
			;;
	esac
fi

#-----------------------[ Functions ]--------------------------------

# Vailid IP Function
valid_ip(){
	local  ip=$1
	local  stat=1
	if [[ $ip =~ (25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9]?[0-9][0-9]?) ]]
	then
		stat=0
	else
		stat=1
	fi
	return $stat
}

# Log Function
log() {
	local message=$1
	local logtype=$2
	echo "[${varArray[DDATE]}] [$logtype] [$USER] - $message" >>${varArray[LOGFILE]}
}

# Confirm Function
confirm() {
	read -p "$1? "$txtpurple"[y/"$txtcyan"N"$txtpurple"]"$txtreset" : "$txtwhite Response; echo -n $txtreset
	if [[ "$Response" =~ (Y|y| ) ]]
	then
		stat=true
	else
		stat=false
	fi
}

# Create DIR
CreateDIR() {
	result=$(sudo mkdir "$1"  2>&1)
	if [ $? != 0 ]
	then
		log "$result" "ERROR "
		PrintError "Creating DIR [ $1 ]"
	else
		log "$1" "CREATE"
		PrintOK "Creating DIR [ $1 ]"
	fi
}

# Copy Files
CopyFiles() {
	result=$(sudo cp "$1" "$2"  2>&1)
	if [ $? != 0 ]
	then
		log "$result" "ERROR "
		PrintError "Copying File [ $1 -> $2 ]"
	else
		log "$1 -> $2" "COPY  "
		PrintOK "Copying File [ $1 -> $2 ]"
	fi
}

# CHOWN Files
ChownFiles() {
	result=$(sudo chown "$1:$2" "$3"  2>&1)
	if [ $? != 0 ]
	then
		log "$result" "ERROR "
		PrintError "Chown DIR    [ $1:$2 - $3 ]"
	else
		log "$3" "CHOWN "
		PrintOK "Chown DIR    [ $1:$2 - $3 ]"
	fi
}

# CHMOD Files
ChmodFiles() {
	result=$(sudo chmod $1 "$2"  2>&1)
	if [ $? != 0 ]
	then
		log "$result" "ERROR "
		PrintError "Chmod DIR    [ $1 - $2 ]"
	else
		log "/var/www/$1" "CHMOD "
		PrintOK "Chmod DIR    [ $1 - $2 ]"
	fi
}

# Write to db.site.domain
AddToBind9() {
	sudo tee -a "${varArray[BINDPATH]}/named.conf.local" << NOF > /dev/null

zone "$1.$2" {
	type master;
	forwarders{};
	file "/etc/bind/zones/db.$1.$2";
	allow-update{key rndc-key;};
};
NOF
	if [ $? != 0 ]
	then
		log "$result" "ERROR "
		PrintError "Writing to file [ named.conf.local ]"
	else
		log "Wtiing to named.conf.local file" "WRTIE "
		PrintOK "Writing to file [ named.conf.local ]"
	fi
}

# Sed file
SedFile() {
	result=$(sudo sed -i "s/$1/$2/g" $3  2>&1)
	if [ $? != 0 ]
	then
		log "$result" "ERROR "
		PrintError "SED file [ $3 | $1 -> $2 ]"
	else
		log "[ $3 | $1 -> $2 ]" "SED   "
		PrintOK "SED file [ $3 | $1 -> $2 ]"
	fi
}

# Enable apache2 site
EnableSite() {
	result=$(sudo a2ensite $1 2>&1)
	if [ $? != 0 ]
	then
		log "$result" "ERROR "
		PrintError "Error enabling site $1"
	else
		log "Enabling site $1" "ENABLE"
		PrintOK "Enabling site $1"
	fi
}

# Disable apache2 site
DisableSite() {
	result=$(sudo a2dissite $1 2>&1)
	if [ $? != 0 ]
	then
		log "$result" "ERROR "
		PrintError "Error disabling site $1"
	else
		log "Disabling site $1" "DISABLE"
		PrintOK "Disabling site $1"
	fi
}

# Restart service
RestartService() {
	result=$(sudo service "$1" restart 2>&1)
	if [ $? != 0 ]
	then
		log "$result" "ERROR "
		PrintError "Restarting $1"
	else
		log "Restarting $1" "RESTART"
		PrintOK "Restarting $1"
	fi
}

# Print fail
PrintError() {
	printf "%${column}s[$(echo -n $txtred)fail$(echo -n $txtreset)]\r$1\n"
}

# Print OK
PrintOK() {
	printf "%${column}s[ OK ]\r$1\n"
}

#---------------------------------[ END Functions ]-----------------------------------

#-------------------------------[ Ask for site name ]---------------------------------
read -p "What is the site name to create? : "$txtwhite site; echo -n $txtreset
if [ -z "$site" ]
then
	echo $txtred"Site name cannot be blank, Aborting!"$txtreset
	echo
	exit 1
fi

#---------------------------------[ Ask for domain ]----------------------------------
read -p "What domain to use? : "$txtwhite domain; echo -n $txtreset
if [ -z "$domain" ]
then
	echo $txtred"Domain name cannot be blank, Aborting!"$txtreset
	echo
	exit 1
fi

#----------------------------------[ Ask for IP ]-------------------------------------
read -p "What is the IP of the server? [ "$txtcyan"${varArray[SERVERIP]}"$txtreset" ] : "$txtwhite sIP; echo -n $txtreset
if [ -n "$sIP" ]
then
	if ! valid_ip $sIP
	then
		echo $txtred"Not a valid IP, Aborting!"$txtreset
		echo
		exit 1
	else
		echo "IP is good [ $sIP ]"
		echo
	fi
else
	echo $txtred"Using default IP : "$txtcyan"${varArray[SERVERIP]}"$txtreset
	sIP="${varArray[SERVERIP]}"
	echo
fi

#--------------------------[ Ask if you want Smarty ]---------------------------------
confirm "Include Smarty-3.1.17"

if [ $stat = "true" ]
then
	IncludeSmarty=true
	echo
else
	IncludeSmarty=false
	echo $txtred"Not Going To Include Smarty-3.1.17 !"$txtreset
	echo
fi

#----------------------------[ Show server details ]----------------------------------
echo $txtbold$txtred"!! Please review server details before continuing !!"$txtreset
echo $txtyellow"Site   : "$txtcyan"www."$site"."$domain $txtreset
echo $txtyellow"IP     : "$txtcyan$sIP$txtreset
if [ $IncludeSmarty = "true" ]
then
	echo $txtyellow"Smarty : "$txtcyan"Will be installed."$txtreset
	echo
else
	echo $txtyellow"Smarty : "$txtcyan"Will "$txtred"NOT"$txtcyan" be installed!"$txtreset
	echo
fi

#-------------------------------[ Ask Are You Ready ]-----------------------------
confirm "Is the above information correct"
if [ $stat = "true" ]
then
	echo
	echo $txtyellow"-----------------------------------[ "$txtcyan"www.$site.$domain"$txtyellow" ]------------------------------------"$txtreset
	echo
else
	echo $txtred"Site information incorrect, Aborting!"$txtreset
	echo
	exit 1
fi

#-----------------------------[ Start Creating DIRs ]-----------------------------

echo $txtyellow"Creating Directories : "$txtreset

# Create Site Root
CreateDIR "/var/www/$site"
ChmodFiles "0755" "/var/www/$site"
ChownFiles "tommy" "tommy" "/var/www/$site"

if [ $IncludeSmarty = "true" ]
then
	# Loop SmartyDir
	for i in "${SmartyDir[@]}"
	do
		# Create the DIRs
		CreateDIR "/var/www/$site/$i"
		ChmodFiles "0755" "/var/www/$site/$i"
		ChownFiles "tommy" "tommy" "/var/www/$site/$i"

		# Is templates_c
		if [ "$i" = "templates_c" ]
		then
			ChownFiles "www-data" "www-data" "/var/www/$site/$i"
			ChmodFiles "0644" "/var/www/$site/$i"
		fi

		# Is cache
		if [ "$i" = "cache" ]
		then
			ChownFiles "www-data" "www-data" "/var/www/$site/$i"
			ChmodFiles "0644" "/var/www/$site/$i"
		fi
	done
else
	# Loop DefaultDir
	for i in "${DefaultDir[@]}"
	do
		CreateDIR "/var/www/$site/$i"
		ChmodFiles "0755" "/var/www/$site/$i"
		ChownFiles "tommy" "tommy" "/var/www/$site/$i"
	done
fi
echo

#-----------------------------[ Start Copying Files ]----------------------------

echo $txtyellow"Copying Files : "$txtreset

CopyFiles "${varArray[INCLUDESPATH]}/jquery-2.1.0.min.js" "/var/www/$site/public_html/js/jquery-2.1.0.min.js"
ChmodFiles "0755" "/var/www/$site/public_html/js/jquery-2.1.0.min.js"
ChownFiles "tommy" "tommy" "/var/www/$site/public_html/js/jquery-2.1.0.min.js"

CopyFiles "${varArray[INCLUDESPATH]}/style.css" "/var/www/$site/public_html/css/style.css"
ChmodFiles "0755" "/var/www/$site/$i"
ChownFiles "tommy" "tommy" "/var/www/$site/$i"

if [ $IncludeSmarty = "true" ]
then
	CopyFiles "${varArray[INCLUDESPATH]}/smarty-index.php" "/var/www/$site/public_html/index.php"
	ChmodFiles "0755" "/var/www/$site/public_html/index.php"
	ChownFiles "tommy" "tommy" "/var/www/$site/public_html/index.php"

	CopyFiles "${varArray[INCLUDESPATH]}/testsmarty.php" "/var/www/$site/public_html/testsmarty.php"
	ChmodFiles "0755" "/var/www/$site/public_html/testsmarty.php"
	ChownFiles "tommy" "tommy" "/var/www/$site/public_html/testsmarty.php"
else
	CopyFiles "${varArray[INCLUDESPATH]}/non-smarty-index.php" "/var/www/$site/public_html/index.php"
	SedFile "{TITLE}" "$site" "/var/www/$site/public_html/index.php"
	ChmodFiles "0755" "/var/www/$site/public_html/index.php"
	ChownFiles "tommy" "tommy" "/var/www/$site/public_html/index.php"
fi

#------------------------[ Start Creating Zone Files ]----------------------------

AddToBind9 "$site" "$domain"
CopyFiles "${varArray[INCLUDESPATH]}/db.site.domain" "${varArray[ZONEFILEPATH]}/db.$site.$domain"
SedFile "{SITE}" "$site" "${varArray[ZONEFILEPATH]}/db.$site.$domain"
SedFile "{DOMAIN}" "$domain" "${varArray[ZONEFILEPATH]}/db.$site.$domain"
SedFile "{IP}" "$sIP" "${varArray[ZONEFILEPATH]}/db.$site.$domain"
ChmodFiles "0644" "${varArray[ZONEFILEPATH]}/db.$site.$domain"
ChownFiles "root" "bind" "${varArray[ZONEFILEPATH]}/db.$site.$domain"
RestartService "bind9"

#------------------------[ Start Creating Apache2 Files ]----------------------------

CopyFiles "${varArray[INCLUDESPATH]}/VirtualHost.file" "${varArray[SITESAVAILABLEPATH]}/$site"
SedFile "{SITE}" "$site" "${varArray[SITESAVAILABLEPATH]}/$site"
SedFile "{DOMAIN}" "$domain" "${varArray[SITESAVAILABLEPATH]}/$site"
ChmodFiles "0644" "${varArray[SITESAVAILABLEPATH]}/$site"
ChownFiles "root" "root" "${varArray[SITESAVAILABLEPATH]}/$site"
EnableSite "$site"
RestartService "apache2"

#------------------------------------[ END ]--------------------------------------
echo $txtreset
exit 0
