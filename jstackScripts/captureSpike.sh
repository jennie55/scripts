#!/bin/bash

THRESHOLD=15

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

LAST_BYTES=$(grep eth0 /proc/net/dev | cut -f 4 -d ' ')
LAST_TIME=$(date +%s)
while true; do
    sleep 10
    
    BYTES=$(grep eth0 /proc/net/dev | cut -f 4 -d ' ')
    TIME=$(date +%s)
    
    let DELTA_BYTES=$BYTES-$LAST_BYTES
    let DELTA_T=$TIME-$LAST_TIME
    let MBITS=$DELTA_BYTES\*8/1024/1024
    let MBPS=$MBITS/$DELTA_T
    
    if [ $MBPS -ge $THRESHOLD ]; then
	PID=$(jps -v | grep "$PORTAL" | cut -f 1 -d ' ')
	if [ -z "PID" ]; then
	    echo No portal found for stack capture
	else
	    FNAME=/tmp/$PORTAL-$(date +%Y%m%d%H%M%S)
            jstack $PID > "${FNAME}.jstack"
	    ps -fLp $PID > "${FNAME}.ps-fLp"
	fi
	sleep 20
    fi
    LAST_BYTES=$BYTES
    LAST_TIME=$TIME
done
