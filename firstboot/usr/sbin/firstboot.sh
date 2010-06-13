#!/bin/sh

# Initially based on the scripts by JohnX/Mer Project - http://wiki.maemo.org/Mer/
# Reworked for the OpenPandora - John Willis/Michael Mrozek
# Reworked again for Neuvoo - Jacob Galbreath - http://neuvoo.org

FBDIR="/var/lib/neuvoo"
FBFILE="firstboot"

# ----

# Check for existing firstboot file

if ! [ -d $FBDIR ] ; then 
	mkdir -p $FBDIR
fi

if ! [ -e $FBFILE ] ; then

#TODO: edit for different keyboard layouts
#xmodmap /etc/skel/.pndXmodmap

TMPINPUT="/tmp/firstboot.input"
RESET_ROOT="yes"
rootpassword1=""
rootpassword2=$rootpassword1
name=""
username=""
password=""
hostname=""
timezone=""
date=""

# ----

# Greet the user.
dialog --title "Neuvoo First Boot." --yesno "Welcome to Neuvoo First Boot!\n\nThis wizard will help you setting up your Neuvoo image for first use.\n\nYou will be asked a few simple questions to personalise and configure your device.\n\nDo you want to set up your unit now or shut the unit down and do it later?" 16 50

# ----

# Reset ROOT's password to something random 
if [ $RESET_ROOT == "yes" ]; then
	rootpwd=$(cat /dev/urandom|tr -dc "a-zA-Z0-9-_\$\?"|fold -w 30|head -n 1)
passwd "root" <<EOF
$rootpwd
$rootpwd
EOF
	while [ "x$rootpassword" = "x" ] ; do
		dialog --title "Password" --inputbox "Please choose a new root password." 8 50 2>$TMPINPUT ; rootpassword1=`cat $TMPINPUT`
		dialog --title "Confirm" --inputbox "Confirm your new root password." 8 50 2>$TMPINPUT ; rootpassword2=`cat $TMPINPUT`
		if [ $rootpassword1 != $rootpassword2 ] ; then 
			dialog --title "Error" --infobox "The passwords do not match.\n\nPlease try again." 8 50;sleep 3
		else 
			if [ x$rootpassword1 = x ] ; then
				dialog --title "Error" --infobox "Password cannot be blank!\n\nPlease try again." 8 50; sleep 3
			else
				rootpassword=$rootpassword1
			fi
		fi
	done
passwd "root" <<EOF
$rootpassword
$rootpassword
EOF
	rm -f $TMPINPUT
	rootpassword=""
	rootpwd=""
fi

# ----

# Setup swap partition if the user has placed an SD with a swap partition on it.

#TODO: set options for swap, either swapfile or partition
#swap_part=$(sfdisk -l /dev/mmcblk? | grep swap | cut -d" " -f1)
#if [ x$swap_part != x ] ; then
#	use_swap=$(zenity --title="Enable swap?" --text "Swap partition found on SD card. Would you like to use it?\n\nWarning: This SD must remain in the system to use the swap." --list --radiolist --column " " --column "Answer" TRUE "Use swap on $swap_part" FALSE "Do not use swap")
#	if [ "$use_swap" = "Use swap on $swap_part" ] ; then
#		swapon $swap_part
#       		echo "$swap_part none swap sw 0 0" >> /etc/fstab
#	fi
#fi

# ----

# Setup the full name and username.

while [ "x$name" = "x" ] ; do
	dialog --title "Please enter your full name" --inputbox "Please enter your full name." 9 50 2>$TMPINPUT ; name=`cat $TMPINPUT`
done

while [ "x$username" = "x" ] ; do
	dialog --title "Enter your username" --inputbox "Please choose a short username.\n\nIt should be all lowercase and contain only letters and numbers." 11 50 2>$TMPINPUT ; username=`cat $TMPINPUT`
done

useradd -c "$name,,," -G adm,audio,video,wheel,plugdev,users,pulse,pulse-access "$username"

# ----

# Setup the users password.

password=""
while [ "x$password" = "x" ] ; do
	dialog --title "Password" --inputbox "Please choose a new password." 8 50 2>$TMPINPUT ; password1=`cat $TMPINPUT`
	dialog --title "Confirm" --inputbox "Confirm your new password." 8 50 2>$TMPINPUT ; password2=`cat $TMPINPUT`
	if [ $password1 != $password2 ] ; then 
		dialog --title "Error" --infobox "The passwords do not match.\n\nPlease try again." 8 50;sleep 3
	else 
		if [ x$password1 = x ] ; then
			dialog --title "Error" --infobox "Password cannot be blank!\n\nPlease try again." 8 50; sleep 3
		else
			password=$password1
		fi
	fi
done

passwd "$username" <<EOF
$password
$password
EOF

password=""
rm -f $TMPINPUT

# ----

# Pick a name for the Neuvoo installed device.

while [ "x$hostname" = "x" ]; do 
	dialog --title "Name your device" --inputbox "Please choose a name for your Neuvoo device.\n\nIt should only contain letters, numbers and dashes." 10 50 2>$TMPINPUT ; hostname=`cat $TMPINPUT`
done

sed 's_hostname=\"\"_hostname=\"$hostname\"_' </etc/conf.d/hostname >/etc/conf.d/hostname
sed 's_127.0.0.1\tlocalhost_127.0.0.1\tlocalhost\t$hostname_' </etc/hosts >/etc/hosts
hostname -F /etc/hostname

# ----

# Set the timezone and date/time
#
while [ "x$timezone" = "x" ] ; do
	dialog --title "Select your timezone" --menu "Please select your timezone" "GMT (London, Lisbon, Portugal, Casablanca, Morocco)" "GMT+1 (Paris, Berlin, Amsterdam, Bern, Stockholm)" "GMT+2 (Athens, Helsinki, Istanbul)" "GMT+3 (Kuwait, Nairobi, Riyadh, Moscow)" "GMT+4 (Abu Dhabi, Iraq, Muscat, Kabul)" "GMT+5 (Calcutta, Colombo, Islamabad, Madras, New Delhi)" "GMT+6 (Almaty, Dhakar, Kathmandu)" "GMT+7 (Bangkok, Hanoi, Jakarta)" "GMT+8 (Beijing, Hong Kong, Kuala Lumpar, Singapore, Taipei)" "GMT+9 (Osaka, Seoul, Sapporo, Tokyo, Yakutsk)" "GMT+10 (Brisbane, Melbourne, Sydney, Vladivostok)" "GMT+11 (Magadan, New Caledonia, Solomon Is)" "GMT+12 (Auckland, Fiji, Kamchatka, Marshall Is., Wellington, Suva)" "GMT-1 (Azores, Cape Verde Is.)" "GMT-2 (Mid-Atlantic)" "GMT-3 (Brasilia, Buenos Aires, Georgetown)" "GMT-4 (Atlantic Time, Caracas)" "GMT-5 (Bogota, Lima, New York)" "GMT-6 (Mexico City, Saskatchewan, Chicago, Guatamala)" "GMT-7 (Denver, Edmonton, Mountain Time, Phoenix, Salt Lake City)" "GMT-8 (Anchorage, Los Angeles, San Francisco, Seattle)" "GMT-9 (Alaska)" "GMT-10 (Hawaii, Honolulu)" "GMT-11 (Midway Island, Samoa)" "GMT-12 (Eniwetok, Kwaialein)" "UTC" "Universal" 30 60 2>$TMPINPUT ; timezone=`cat $TMPINPUT`
done
timezone=`echo $timezone | sed  's/(.*)//g'`
echo $timezone
echo rm /etc/localtime && ln -s /usr/share/zoneinfo/Etc/$timezone /etc/localtime

while [ "x$date" = "x" ] ; do
	dialog --title "Please enter the current date (MMDDhhmmYY)" 6 10 2>$TMPINPUT ; date=`cat $TMPINPUT` 
done

date $date

# ----

# Finsh up and boot the system.

dialog --title "Finished" --infobox "This concludes the First Boot Wizard.\n\nThankyou for using Neuvoo. Enjoy using the device!" 10 50; sleep 5

# ----

# Write the control file so this script is not run on next boot 
# (hackish I know but I want the flexability to drop a new script in later esp. in the early firmwares).
 
touch $FBDIR/$FBFILE
# Make the control file writeable by all to allow the user to delete to rerun the wizard on next boot.
chmod 0666 $FBDIR/$FBFILE

fi
