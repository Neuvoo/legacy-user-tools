#!/bin/sh
# module to create users via dialog
# Neuvoo Project, viridior, 2010
username=""
password=""

#get user data
while [ "x$name" = "x" ] ; do
    dialog --title "Please enter your full name" --inputbox "Please enter your full name." 9 50 2>$TMPINPUT ; name=`cat $TMPINPUT`
done

while [ "x$username" = "x" ] ; do
    dialog --title "Enter your username" --inputbox "Please choose a short username.\n\nIt should be all lowercase and contain only letters and numbers." 11 50 2>$TMPINPUT ; username=`cat $TMPINPUT`
done

if ! [ testrun == yes" ] ;  then
	useradd -c "$name,,," -G adm,audio,video,wheel,plugdev,users,pulse,pulse-access "$username"
fi

#set users password.
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

if ! [ testrun == "yes" ] ; then
	passwd "$username" <<EOF
	$password
	$password
	EOF
	rm -f $TMPINPUT
fi

password=""
