#!/bin/sh

SSH=/usr/bin/ssh

for HOST in eda1-pre eda2-pre eda-admin-pre; do
    echo "Starting AMQ on $HOST"
    ${SSH} eda@$HOST "./AMQ_GW/bin/activemq start"
    STOPEXIT=$?
    if [ $STOPEXIT -ne 0 ]; then
        echo "There was a problem starting AMQ on $HOST. "
        exit $STOPEXIT
    fi
done

exit 0
