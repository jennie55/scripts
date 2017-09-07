#!/bin/sh -x

SSH=/usr/bin/ssh

for HOST in eda1-nightly eda2-nightly eda3-nightly eda4-nightly eda-admin-nightly; do

    echo "Starting EDA on $HOST"
    ${SSH} eda@$HOST "./start_all.sh"
    STOPEXIT=$?
    if [ $STOPEXIT -ne 0 ]; then
	echo "There was a problem starting EDA on $HOST. "
	exit $STOPEXIT
    fi
done

exit 0
