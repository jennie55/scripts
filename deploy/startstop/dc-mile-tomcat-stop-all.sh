#!/bin/sh -x

SSH=/usr/bin/ssh
SLEEP=/bin/sleep

for HOST in dc1-mile dc2-mile; do

    echo "Stopping DC on $HOST"
    ${SSH} datapipe@$HOST "./stop_all.sh"
    STOPEXIT=$?
    if [ $STOPEXIT -ne 0 ]; then
	echo "There was a problem stopping DC on $HOST. "
	exit $STOPEXIT
    fi
done

# RB - 5/21/15 - stop_all.sh script will wait for processes to stop
#${SLEEP} 60

exit 0
