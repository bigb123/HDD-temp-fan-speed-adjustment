#!/bin/bash

FAN_PATH=/sys/devices/platform/gpio_fan/hwmon/hwmon0/fan1_target

FAN_OFF=5000
FAN_SLOW=3250
FAN_MED=1500
FAN_FULL=0

HDD_PATH="/dev/sdb"

disk_output_value=$(/usr/sbin/hddtemp -n $HDD_PATH 2>&1)

# echo "disk_output_value: $disk_output_value" 

case $disk_output_value in

    # If the drive is stopped - just stop the fan as well
    *"drive is sleeping")
        echo $FAN_OFF > $FAN_PATH
    ;;
    
    # When the disk temperature is low - just keep the fan off
    [0-4][0-9])
        echo $FAN_OFF > $FAN_PATH
    ;;

    # If temp is above 50 - spin the fan a bit
    5[0-4])
        echo $FAN_SLOW > $FAN_PATH
    ;;

    # Disk getting hot - spin the fan more
    5[5-9])
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
