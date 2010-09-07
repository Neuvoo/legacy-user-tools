#!/bin/sh
# module to set system hostname via dialog
# Neuvoo Project, viridior, 2010
TMPINPUT="/tmp/firstboot.input"
hostname=""
while [ "x$hostname" = "x" ]; do
    dialog --title "Name your device" --inputbox "Please choose a name for your Neuvoo device.\n\nIt should only contain letters, numbers and dashes." 10 50 2>$TMPINPUT ; hostname=`cat $TMPINPUT`
done

if ! [ testrun == "yes" ] ; then
	sed 's_hostname=\"\"_HOSTNAME=\"$hostname\"_' </etc/conf.d/hostname >/etc/conf.d/hostname
	sed 's_127.0.0.1\tlocalhost_127.0.0.1\tlocalhost\t$hostname_' </etc/hosts >/etc/hosts
	hostname $hostname
fi
