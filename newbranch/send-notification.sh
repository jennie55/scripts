#!/bin/sh

# parameters
LOG_FILE=$1
BRANCH_NAME=$2
RECIPIENTS=$3

# log filename is required
if [ -z "$LOG_FILE" ] ; then 
	exit 2
fi

# send an email
export DATE=`date +%D`
export SUBJECT="Change log $BRANCH_NAME, $DATE"
export MESSAGE=`cat $LOG_FILE`


#
/usr/sbin/sendmail $RECIPIENTS <<EOF
subject:${SUBJECT}
from:nwfsre@one.verizon.com
${MESSAGE}
EOF


exit 0
