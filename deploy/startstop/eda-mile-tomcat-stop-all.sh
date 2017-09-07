#!/bin/sh -x

SSH=/usr/bin/ssh
SLEEP=/bin/sleep

for HOST in eda1-mile eda2-mile eda3-mile eda4-mile eda-admin-mile; do

    echo "Stopping EDA on $HOST"
    ${SSH} eda@$HOST "./stop_all.sh"
    STOPEXIT=$?
    if [ $STOPEXIT -ne 0 ]; then
	echo "There was a problem stopping EDA on $HOST. "
	exit $STOPEXIT
    fi
done

# RB - 5/21/15 - stop_all.sh script will wait for processes to stop
#${SLEEP} 60

exit 0
