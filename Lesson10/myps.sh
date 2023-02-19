#!/bin/bash

usage() { 
	echo "Usage: $0 ax" 1>&2;
	echo ""
	echo "OPTIONS"
	echo ""
	echo "a      Select all processes except both session leaders (see getsid(2))"
        echo "       and processes not associated with a terminal."
	echo ""
	echo "x      Lift the BSD-style ""must have a tty"" restriction, which is"
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
for i in "$@"; do
  case $i in
    -a)
      ALLPROCESSES=1
      shift
      ;;
    -x)
      BSDSTYLE=1
      shift
      ;;
    -ax|ax)
      ALLPROCESSES=1
      BSDSTYLE=1
      ;;
    -*|--*)
      # echo "Unknown option $i"
      usage
      exit 1
      ;;
    *)
      usage
      exit 1
      ;;
  esac
done

if [ -z "$ALLPROCESSES" ] || [ -z "$BSDSTYLE" ]; then
   echo "Not valid options [$@] ..."
   usage
   exit 1
fi

# number of clock ticks in a second
CLK_TCK=$(getconf CLK_TCK)
# Width of a terminal window
TTYCOLS="$(tput cols)"
MAXCOMMANDLEN=$(($TTYCOLS-31))

#-40
fmt="%8s %-10s %-4s %-4s"
printf "$fmt" "PID" "TTY" "STAT" "TIME" 
echo " COMMAND"

for PID in $(ls -v /proc | grep -E '^[0-9]+$' ) 
do
	if [[ -f /proc/$PID/status ]] 
	then
	        # PID=$proc
		TTY=$(readlink -f /proc/$PID/fd/0 | sed 's:/dev/::')
		if [ "$TTY" = '' ] 
		then
			TTY="?"
		fi

		# https://stackoverflow.com/questions/39066998/what-are-the-meaning-of-values-at-proc-pid-stat
		# https://www.baeldung.com/linux/total-process-cpu-usage
		PROCESS_STAT=($(sed -E 's/\([^)]+\)/X/' "/proc/$PID/stat"))
		STAT=${PROCESS_STAT[2]}
		# https://stackoverflow.com/questions/39066998/what-are-the-meaning-of-values-at-proc-pid-stat
		# Get process nice
		NICE="$(cat /proc/$PID/stat | awk '{print $19}')"
		if [ "$NICE" -lt "0" ]; then
		 	STAT="${STAT}<"
		elif [ "$NICE" -gt "0" ]; then
			STAT="${STAT}N"
		fi
		# Get
		# https://unix.stackexchange.com/questions/18166/what-are-session-leaders-in-ps
		#  If PID == PGID, then this process is a process group leader.
		PGRP="$(cat /proc/$PID/stat | awk '{print $5}')"
		if (( $PID == $PGRP )); then
			STAT="${STAT}s"
		fi
		# Get "is multi-threaded"
                # https://www.golinuxcloud.com/check-threads-per-process-count-processes/
                # See 1. Using PID task
                MULTITHRD="$(ls /proc/$PID/task | wc -l)"
                if [ "$MULTITHRD" -gt 1 ]; then
                        STAT="${STAT}l"
		fi
		# Get foreground process group
		FRGGRP="$(cat /proc/$PID/stat | awk '{print $8}')"
		if [ "$FRGGRP" -eq "$PID" ]; then
			STAT="${STAT}+"
		fi

		# time calculation
		PROCESS_UTIME=${PROCESS_STAT[13]}
		PROCESS_STIME=${PROCESS_STAT[14]}
		let PROCESS_UTIME_SEC="$PROCESS_UTIME / $CLK_TCK"
		let PROCESS_STIME_SEC="$PROCESS_STIME / $CLK_TCK"
		let PROCESS_USAGE_SEC="$PROCESS_UTIME_SEC + $PROCESS_STIME_SEC"
		printf -v TIME "%2d:%02d" "$(($PROCESS_USAGE_SEC/60))" "$(($PROCESS_USAGE_SEC%60))"

		# COMMAND="$(tr -d '\0' < /proc/$PID/cmdline)"
		COMMAND="$(cat /proc/$PID/cmdline | tr '\000' ' ' )"
		if [ "$COMMAND" = '' ]
		then
		  COMMAND="[$(cat /proc/$PID/status | grep Name: | awk '{print $2}' | sed -Ez '$ s/\n+$//')]"
		fi

		CMD=${COMMAND:1:MAXCOMMANDLEN}
		# Hole line output given the TTY width
		# несколько странный вывод, но иначе что-то у меня переводы строки лезут
		printf "$fmt" $PID $TTY $STAT $TIME
		echo " $CMD"
    	fi
done
