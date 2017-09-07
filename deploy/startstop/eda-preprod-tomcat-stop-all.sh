#!/bin/sh

SSH=/usr/bin/ssh
SLEEP=/bin/sleep

for HOST in eda1-pre eda2-pre eda-admin-pre; do

    echo "Stopping EDA on $HOST"
    ${SSH} eda@$HOST "./stop_all.sh"
    STOPEXIT=$?
    if [ $STOPEXIT -ne 0 ]; then
	echo "There was a problem stopping EDA on $HOST. "
	exit $STOPEXIT
    fi
done


exit 0
