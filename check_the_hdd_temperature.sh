#!/bin/bash
#
# Script to change the mainboard fan speed depends on the hard disk temperature
#
# Requirements:
# - fatrace
# - hddtemp

FAN_PATH="/sys/devices/platform/gpio_fan/hwmon/hwmon0/fan1_target"

FAN_OFF=5000
FAN_SLOW=3250
FAN_MED=1500
FAN_FULL=0

HDD_PATH="/dev/sdb"

# The problem with hddtemp is that it generates activity on the hard 
# disk every time it checks for the temperature. 
#
# To mitigate it we will check first if there's any files acivity 
# on the hard disk. If not - we will slowly spin down the fans not
# checking the temperature. (Risky but I have no other idea for now)

MOUNT_POINT="/home/nasbackup/storage"

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

    # Do not execute any more code in this run
    exit 0
fi

disk_output_value=$(/usr/sbin/hddtemp -n $HDD_PATH 2>&1)

# echo "disk_output_value: $disk_output_value" 

case $disk_output_value in

    # If the drive is stopped - just stop the fan as well
    *"drive is sleeping")
        echo $FAN_OFF > $FAN_PATH
    ;;
    
    # When the disk temperature is low - just keep the fan off
    [0-2][0-9])
        echo $FAN_OFF > $FAN_PATH
    ;;

    # If temp is above 30 - spin the fan a bit
    3[0-9])
        echo $FAN_SLOW > $FAN_PATH
    ;;

    # Disk getting hot - spin the fan more
    4[0-9])
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
