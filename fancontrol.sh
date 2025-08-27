#!/bin/bash

# Copyright (c) 2025 James Oakey
# 
# This script is released under the MIT License. 
#      https://opensource.org/licenses/MIT

# Script for defining CPU fan behavior on the ThinkPad T480
# running MacOS with OpenCore
#
# Requires `ioio` and `YogaSMC.kext` 
# - ioio must be callable from /usr/local/bin/ioio
# 
# Temperature thresholds + speed ranges can be adjusted in the main while loop
# Speed ranges: 0 (off) to 7 (full blast)
#
# Time interval between each temperature check can be adjusted by `sleep_time`


RED="\033[91m" GREEN="\033[32m" CYAN="\033[96m" RESET="\033[0m"

console_templog=false
ioio_msglog=false
temp_report="N/A"
fan_report="N/A"
sleep_time=1

while getopts "li" opt; do
	case $opt in
		l) console_templog=true ;;
		i) ioio_msglog=true ;;
	esac
done

call_thinkVPC () {
	if [[ $console_templog = true || $temp_report = true ]]; then echo -e "\n"; fi
	if [ $console_templog = true ]; then 
        echo -e $temp_report
        echo -e $fan_report
    fi

	if [ $ioio_msglog = true ]; then
		/usr/local/bin/ioio -s ThinkVPC FanSpeed $1 \
			| sed 's/^ioio: //' \
			| awk -v cyan="$CYAN" -v reset="$RESET" '{$1="[" cyan "ioio" reset "]"; print}'
	else /usr/local/bin/ioio -s ThinkVPC FanSpeed $1 > /dev/null; fi

	
	sleep $sleep_time
}

while true; do
	cpu_temp=$(osx-cpu-temp | sed 's/[^0-9.]//g')
	cpu_temp=${cpu_temp%.*}
    fan_speed=$(smc -f | sed -n 's/.*Current speed : \([0-9]*\).*/\1/p')

	temp_report="[${RED}cpu${RESET}] ${cpu_temp}°C"
    fan_report="[${GREEN}fan${RESET}] ${fan_speed} RPM"

	if   ((cpu_temp >= 0 && cpu_temp <= 68));   then call_thinkVPC 0
	elif ((cpu_temp >= 68 && cpu_temp <= 70));  then call_thinkVPC 1
	elif ((cpu_temp >= 70 && cpu_temp <= 80));  then call_thinkVPC 2		
	elif ((cpu_temp >= 70 && cpu_temp <= 85));  then call_thinkVPC 4
	elif ((cpu_temp >= 85 && cpu_temp <= 100)); then call_thinkVPC 6
	elif ((cpu_temp >= 100));              	    then call_thinkVPC 7
	fi
done
