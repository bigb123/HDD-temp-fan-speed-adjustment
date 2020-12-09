#!/bin/bash
#
# Script to change the mainboard fan speed depends on the hard disk temperature
#
# Requirements:
# - fatrace - to check the files activity on the disk
# - hddtemp - to check the temperature of the disk

# It will be used to avoid running new instance of this script when the 
# old one is still running.
PIDFILE="/var/run/check_hdd_temperature.pid"

FAN_PATH="/sys/devices/platform/gpio_fan/hwmon/hwmon0/fan1_target"

FAN_OFF=5000
FAN_SLOW=3250
FAN_MED=1500
FAN_FULL=0

HDD_PATH="/dev/sdb"
MOUNT_POINT="/home/nasbackup/storage"

if [ -f $PIDFILE ]; then
    if [ $(ps -p $(cat $PIDFILE) &>/dev/null; echo $?) == 0 ]; then 
        # This process is already running
        exit 0
    fi
fi

# Chreate new pid file so new instance of the same script will not appear.
echo $$ > $PIDFILE

# The problem with hddtemp is that it generates activity on the hard 
# disk every time it checks for the temperature. 
#
# To mitigate it we will check first if there's any files acivity 
# on the hard disk. If not - we will slowly spin down the fan not
# checking the temperature but still letting the fan rotate slowly. 

# Go to the mount point of the disk and check if there's any activity
# on the files.
#
# If not - just spin down the fan a bit.
#
if [[ -z $(cd $MOUNT_POINT && /usr/sbin/fatrace -c -s 1) ]]; then

    case $(/usr/bin/cat $FAN_PATH) in

        $FAN_SLOW)
            echo $FAN_OFF > $FAN_PATH
        ;;

        $FAN_MED)
            echo $FAN_SLOW > $FAN_PATH
        ;;

        $FAN_FULL)
            echo $FAN_MED > $FAN_PATH
        ;;

    esac

else
    # The temperature tresholds of the hard disk are set according
    # to https://www.buildcomputers.net/hdd-temperature.html

    # Temperature check (generates traffic on the disk)
    case $(/usr/sbin/hddtemp -n $HDD_PATH 2>&1) in

        # If the drive is stopped - just stop the fan as well
        *"drive is sleeping")
            echo $FAN_OFF > $FAN_PATH
        ;;
        
        # When the disk temperature is low - just keep the fan off
        [0-2][0-9])
            echo $FAN_OFF > $FAN_PATH
        ;;

        # If temp is above 30 - spin the fan a bit
        3[0-4])
            echo $FAN_SLOW > $FAN_PATH
        ;;

        # Disk getting hot - spin the fan more
        3[5-9])
            echo $FAN_MED > $FAN_PATH
        ;;

        # Disk is very hot - cool it down now!
        [0-9][0-9])
            echo $FAN_FULL > $FAN_PATH
        ;;

        # *)
        #     echo "Something happened and I don't know what"
        # ;;

    esac
fi

# Remove pid file so next process can start correctly
rm $PIDFILE
