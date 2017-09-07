#!/bin/bash

THRESHOLD=50

CORES=$(grep MHz /proc/cpuinfo | wc -l)

function cputime()
{
    PID=$1
    TIMES=($(cat /proc/$PID/stat | cut -f 14-15 -d ' '))
    let TOTAL=${TIMES[0]}+${TIMES[1]}
    echo $TOTAL
}


if [ -z "$1" ]; then
    PORTAL=Portal$(hostname | sed 's/app\([0-9]\+\)-\(xo\|stage\|nightly\).*/\1/')
else
    PORTAL=$1
fi

PID=$(jps -v | grep "$PORTAL" | cut -f 1 -d ' ')

if [ -z "$PID" ]; then
    echo Portal $PORTAL not found
    exit
fi

echo Targeting $PORTAL \($PID\)

LAST_CPU=$(cputime $PID)
LAST_TIME=$(date +%s)
while true; do
    sleep 10
   
    PID=$(jps -v | grep "$PORTAL" | cut -f 1 -d ' ')
    if [ -z "$PID" ]; then
        echo No portal found
	continue;
    fi

    CPU=$(cputime $PID)
    TIME=$(date +%s)
    
    let DELTA_CPU=$CPU-$LAST_CPU
    let DELTA_T=$TIME-$LAST_TIME
    let CPU_USAGE=$DELTA_CPU/$DELTA_T
    let AVERAGE_CPU=$CPU_USAGE/$CORES
   
    if [ $AVERAGE_CPU -ge $THRESHOLD ]; then
	FNAME=/tmp/$PORTAL-$(date +%Y%m%d%H%M%S)-CPU
        jstack $PID > "${FNAME}.jstack"
        ps -fLp $PID > "${FNAME}.ps-fLp"
	sleep 20
    fi
    LAST_CPU=$CPU
    LAST_TIME=$TIME
done
