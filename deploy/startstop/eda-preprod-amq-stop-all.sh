#!/bin/sh

SSH=/usr/bin/ssh

for HOST in eda1-pre eda2-pre eda-admin-pre; do
    echo "Stopping AMQ on $HOST"
    ${SSH} eda@$HOST "./AMQ_GW/bin/activemq stop"
    STOPEXIT=$?
    if [ $STOPEXIT -ne 0 ]; then
        echo "There was a problem stopping AMQ on $HOST. "
        exit $STOPEXIT
    fi

done

exit 0
