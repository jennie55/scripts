#!/bin/sh

SSH=/usr/bin/ssh
SLEEP=/bin/sleep

for HOST in eda1-stage eda2-stage eda3-stage eda4-stage eda-admin-stage; do

    echo "Stopping EDA on $HOST"
    ${SSH} eda@$HOST "./stop_all.sh"
    STOPEXIT=$?
    if [ $STOPEXIT -ne 0 ]; then
	echo "There was a problem stopping EDA on $HOST. "
	exit $STOPEXIT
    fi
done


exit 0
