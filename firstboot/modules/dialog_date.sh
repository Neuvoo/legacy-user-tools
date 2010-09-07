#!/bin/sh
# module to set system date & timezone via dialog
# Neuvoo Project, viridior, 2010
timezone=""
date=""

while [ "x$timezone" = "x" ] ; do
    dialog --title "Select your timezone" --menu "Please select your timezone" "GMT (London, Lisbon, Portugal, Casablanca, Morocco)" "GMT+1 (Paris, Berlin$
done
timezone=`echo $timezone | sed  's/(.*)//g'`

if ! [ testrun == yes ] ; then
	echo rm /etc/localtime && ln -s /usr/share/zoneinfo/Etc/$timezone /etc/localtime
fi

while [ "x$date" = "x" ] ; do
    dialog --title "Please enter the current date (MMDDhhmmYY)" 6 10 2>$TMPINPUT ; date=`cat $TMPINPUT`
done

if ! [ testrun == yes ] ; then
	date $date
fi
