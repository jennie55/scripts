#!/bin/sh

SSH=/usr/bin/ssh

for HOST in eda1-stage eda2-stage eda3-stage eda4-stage eda-admin-stage; do

    echo "Starting EDA on $HOST"
    ${SSH} eda@$HOST "./start_all.sh"
    STOPEXIT=$?
    if [ $STOPEXIT -ne 0 ]; then
	echo "There was a problem starting EDA on $HOST. "
	exit $STOPEXIT
    fi
done

exit 0
