#!/bin/sh
# module to set system password via dialog
# Neuvoo Project, viridior, 2010
rootpassword1=""
rootpassword2=$rootpassword1
name=""
username=""
password=""

if ! [ testrun == "yes" ] ; then
	#scramble root passwd
	rootpwd=$(cat /dev/urandom|tr -dc "a-zA-Z0-9-_\$\?"|fold -w 30|head -n 1)
	passwd "root" <<EOF
	$rootpwd
	$rootpwd
	EOF
fi

#get root passwd
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

# set root passwd
if [ testrun == "yes" ] ; then
	passwd "root" <<EOF
	$rootpassword
	$rootpassword
	EOF
	rm -f $TMPINPUT
fi

rootpassword=""
rootpwd=""
