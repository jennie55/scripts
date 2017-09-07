#!/bin/sh

SSH=/usr/bin/ssh

for HOST in eda1-nightly eda2-nightly eda3-nightly eda4-nightly eda-admin-nightly; do
    echo "Starting AMQ on $HOST"
    ${SSH} eda@$HOST "cd ~/AMQ_GW/bin; ./start.sh"
    STOPEXIT=$?
    if [ $STOPEXIT -ne 0 ]; then
        echo "There was a problem starting AMQ on $HOST. "
        exit $STOPEXIT
    fi
done

exit 0
