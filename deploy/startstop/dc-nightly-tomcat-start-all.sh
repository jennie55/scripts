#!/bin/sh -x

SSH=/usr/bin/ssh

for HOST in dc1-nightly dc2-nightly; do

    echo "Starting DC on $HOST"
    ${SSH} datapipe@$HOST "./start_all.sh"
    STOPEXIT=$?
    if [ $STOPEXIT -ne 0 ]; then
	echo "There was a problem starting DC on $HOST. "
	exit $STOPEXIT
    fi
done

exit 0