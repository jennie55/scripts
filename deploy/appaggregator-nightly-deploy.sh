#!/bin/sh

ZIP=/usr/bin/zip
SCP=/usr/bin/scp
SSH=/usr/bin/ssh
FILEPATTERN=dist
FILENAME=appAggregator-NIGHTLY-SNAPSHOT-web.zip
HOST1=apache1-nightly
#HOST2=apache2-nightly
ZIPDEST=/tmp
MEDIADIR=/var/www/html.dev25web/appaggregator

CWD=`pwd`

# Greeting
echo "Executing $0 in $CWD"

# Copy latest media zip to apache nodes
echo "Copying latest ng-portal zip to $HOST1:${ZIPDEST}/${FILENAME}"
${SCP} ${FILENAME} static@${HOST1}:${ZIPDEST}/${FILENAME} 
SCP1EXIT=$?
if [ $SCP1EXIT -ne 0 ]; then
	echo "There was a problem with scp. Abandoning script" >&2
	exit $SCP1EXIT
fi
#echo "Copying latest media zip to $HOST2"
#${SCP} ./media-nightly.zip static@${HOST2}:${ZIPDEST}/${FILENAME}
#SCP2EXIT=$?
#if [ $SCP2EXIT -ne 0 ]; then
#	echo "There was a problem with scp. Abandoning script" >&2
#	exit $SCP2EXIT
#fi

# Delete the contents of the destination directory
echo "Cleaning ${MEDIADIR}/* on $HOST1"
${SSH} static@${HOST1} "rm -rf ${MEDIADIR}/*"
SSH1EXIT=$?
if [ $SSH1EXIT -ne 0 ]; then
    echo "There was a problem with ssh/emptying the destination directory. Abandoning script" >&2
    exit $SSH1EXIT
fi

# Unroll the zip
echo "Unzipping on $HOST1"
${SSH} static@${HOST1} "unzip -o ${ZIPDEST}/${FILENAME} -d ${MEDIADIR}"
SSH1EXIT=$?
if [ $SSH1EXIT -ne 0 ]; then
	echo "There was a problem with ssh/unzip. Abandoning script" >&2
	exit $SSH1EXIT
fi
#echo "Unzipping on $HOST2"
#${SSH} static@${HOST2} "unzip -o ${ZIPDEST}/${FILENAME} -d ${MEDIADIR}"
#SSH2EXIT=$?
#if [ $SSH2EXIT -ne 0 ]; then
#	echo "There was a problem with ssh/unzip. Abandoning script" >&2
#	exit $SSH2EXIT
#fi

# Clean up
echo "Removing ${ZIPDEST}/${FILENAME} from ${HOST1}"
${SSH} static@${HOST1} "rm ${ZIPDEST}/${FILENAME}"
RM1EXIT=$?
if [ $RM1EXIT -ne 0 ]; then
	echo "There was a problem with ssh/rm. Abandonig script" >&2
	exit $RM1EXIT
fi
#echo "Removing ${ZIPDEST}/${FILENAME} from ${HOST2}"
#${SSH} static@${HOST2} "rm ${ZIPDEST}/${FILENAME}"
#RM2EXIT=$?
#if [ $RM2EXIT -ne 0 ]; then
#	echo "There was a problem with ssh/rm. Abandonig script" >&2
#	exit $RM2EXIT
#fi
