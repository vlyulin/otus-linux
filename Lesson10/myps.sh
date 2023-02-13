#!/bin/bash

usage() { 
	echo "Usage: $0 [options]" 1>&2;
	echo ""
	echo "OPTIONS"
	echo ""
	echo "-a     Select all processes except both session leaders (see getsid(2))"
        echo "       and processes not associated with a terminal."
	echo ""
	echo "-x     Lift the BSD-style ""must have a tty"" restriction, which is"
        echo "       imposed upon the set of all processes when some BSD-style"
        echo "       (without ""-"") options are used or when the ps personality"
        echo "       setting is BSD-like.  The set of processes selected in this"
        echo "       manner is in addition to the set of processes selected by other"
        echo "       means.  An alternate description is that this option causes ps"
        echo "       to list all processes owned by you (same EUID as ps), or to list"
        echo "       all processes when used together with the a option."

	exit 1; 
}

# Обработка ключей
while getopts ":f:a:h:" o; do
    case "${o}" in
        a)
            # outrowsnum=${OPTARG}
	    echo "opt a"
            ;;
        f)
            # email=${OPTARG}
	    echo "opt x"
            ;;
        h)
            usage
            ;;
        *)
            usage
            ;;
    esac
    echo "o=${o}"
done
shift $((OPTIND-1))

# number of clock ticks in a second
CLK_TCK=$(getconf CLK_TCK)

fmt="%8s %-10s %-4s %-4s %-40s\n"
# fmt="%8s %-10s %-4s %2d:%02d %-40s\n"
printf "$fmt" "PID" "TTY" "STAT" "TIME" "COMMAND"

for PID in $(ls -v /proc | grep -E '^[0-9]+$') 
do
	if [[ -f /proc/$PID/status ]] 
	then
	        # PID=$proc
		TTY=$(readlink -f /proc/$PID/fd/0 | sed 's:/dev/::')
		if [ "$TTY" = '' ] 
		then
			TTY="?"
		fi

		# https://www.baeldung.com/linux/total-process-cpu-usage
		PROCESS_STAT=($(sed -E 's/\([^)]+\)/X/' "/proc/$PID/stat"))
		STAT=${PROCESS_STAT[2]}
		# time calculation
		PROCESS_UTIME=${PROCESS_STAT[13]}
		PROCESS_STIME=${PROCESS_STAT[14]}
		let PROCESS_UTIME_SEC="$PROCESS_UTIME / $CLK_TCK"
		let PROCESS_STIME_SEC="$PROCESS_STIME / $CLK_TCK"
		let PROCESS_USAGE_SEC="$PROCESS_UTIME_SEC + $PROCESS_STIME_SEC"
		# TIME=$(date -d@$PROCESS_USAGE_SEC -u +%M:%S)
		# TIME="$(($PROCESS_USAGE_SEC/60%60)):$(($PROCESS_USAGE_SEC%60))"
		printf -v TIME "%2d:%02d" "$(($PROCESS_USAGE_SEC/60))" "$(($PROCESS_USAGE_SEC%60))"

		COMMAND=$(strings < /proc/$PID/cmdline)
		if [ "$COMMAND" = '' ]
		then
		  COMMAND="[$(cat /proc/$PID/status | grep Name: | awk '{print $2}' | sed -Ez '$ s/\n+$//')]"
		fi
		# COMMAND="${COMMAND//[$'\t\r\n']}"
		# COMMAND=${COMMAND//$'\n'/}
		# Замена "\n" на пробел
		COMMAND="${COMMAND//[$'\n']/ }"
		# Заменяем множество пробелов на один
		# COMMAND="${COMMAND//+( )/ }"
		# COMMAND=$(echo ${COMMAND} | tr -d '\n')
    		
		printf "$fmt" $PID $TTY $STAT $TIME $COMMAND
    	fi
done
