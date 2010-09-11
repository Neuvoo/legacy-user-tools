#!/bin/sh
# module to build system swap file via dialog
# Neuvoo Project, viridior, 2010
TMPINPUT="/tmp/firstboot.input"
#TODO: set options for swap, either swapfile or partition
#swap_part=$(sfdisk -l /dev/mmcblk? | grep swap | cut -d" " -f1)
#if [ x$swap_part != x ] ; then
#       use_swap=$(zenity --title="Enable swap?" --text "Swap partition found on SD card. Would you like to use it?\n\nWarning: This SD must remain in the system to use the swap." --list --radiolist --column " " --column "Answer" TRUE "Use swap on $swap_part" FALSE "Do not use swap")
#       if [ "$use_swap" = "Use swap on $swap_part" ] ; then
#               swapon $swap_part
#                       echo "$swap_part none swap sw 0 0" >> /etc/fstab
#       fi
#fi

