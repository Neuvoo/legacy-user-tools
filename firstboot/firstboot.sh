#!/bin/sh

# Initially based on the scripts by JohnX/Mer Project - http://wiki.maemo.org/Mer/
# Reworked for the OpenPandora - John Willis/Michael Mrozek
# Modularized and reworked again for Neuvoo - Jacob Galbreath - http://neuvoo.org

FBDIR="/usr/lib/neuvoo/firstboot"
FBFILE=".firstboot"
reset_root="no"
no_fbfile="no"
testrun="no"
TMPDIR="/tmp"
TMPINPUT="$TMPDIR/.firstboot.input"

function usage() {
    echo
    echo "Usage: $(basename $0) -d <device> -f <format> -r -n"
    echo
    echo "  -d <device>: override device detection and force <device name>"
	echo "		accepted devices: beagle (default), touchbook"
	echo "  -f <format>: override format detection and force <format>"
	echo "		accepted formats: dialog"
	echo "  -n: do not write $FBFILE allowing firstboot to run every boot"
	echo "  -r: forces reset of root passwd"
	echo "  -t: run in test mode, do no write files"
    echo
}

while getopts d:f:n:r:t opt
do
	case "$opt" in
		d) device="$OPTARG";;
		f) format="$OPTARG";;
		n) no_fbfile="yes";;
		r) reset_root="yes";;
		t) TMPDIR="$FBDIR/tmp"
			testrun="yes"
			export TMPDIR
			export testrun;;
		\?) usage;;
	esac
done

# Check for existing firstboot directory
if ! [ -d $FBDIR ] ; then 
	mkdir -p $FBDIR
fi

# Check for existing firstboot file
if [ -e "${FBDIR}/${FBFILE}" ] ; then
	exit 0
fi

# If in test mode ensure ROOTDIR exists
if [ testrun == "yes" ] ; then
	if ! [ -d $TMPDIR ] ; then 
		mkdir -p $TMPDIR
	fi
fi

export TMPINPUT

# Greet the user.
./modules/dialog_welcome.sh

# Set root passwd
if [ $reset_root == "yes" ] ; then 
	./modules/dialog_passwd.sh
fi

# Setup swap partition if the user has placed an SD with a swap partition on it.
./modules/dialog_swap.sh

# Create user accounts
./modules/dialog_users.sh

# Set system hostname
./modules/dialog_hostname.sh

# Set the timezone and date/time
./modules/dialog_date.sh

# Finsh up and boot the system.
./modules/diaglog_finish.sh

#set FBFILE so firstboot only runs the first time
if ! [ testrun == "yes" } ; then
	if ! [ $no_fbfile == "yes" ] ; then
		touch $FBDIR/$FBFILE
		chmod 0600 $FBDIR/$FBFILE
	fi
fi
