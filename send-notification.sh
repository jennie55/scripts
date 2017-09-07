#!/bin/sh

# parameters
LOG_FILE=$1
SUBJECT_SUFFIX=$2

# log filename is required
if [ -z "$LOG_FILE" ] ; then 
	exit 2
fi

# send an email
export RECIPIENTS="NWFSRE@one.verizon.com;NWFQA@one.verizon.com;NWFDev-internal@one.verizon.com"
export REVISION=$(grep 'From revision ' $LOG_FILE)
export SUBJECT="Building revision. $REVISION  $SUBJECT_SUFFIX"
export MESSAGE=`cat $LOG_FILE`

#
/usr/sbin/sendmail "$RECIPIENTS" <<EOF
subject:${SUBJECT}
from:nwfsre@one.verizon.com
${MESSAGE}
EOF


exit 0
