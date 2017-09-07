#!/bin/sh

SSH=/usr/bin/ssh
WGET=/usr/bin/wget
VERSION=`grep version pom.xml |grep SNAPSHOT|head -1|cut -f 2 -d \<|cut -d \> -f 2`
FILE=api-docs-$VERSION.tar
KEY=~/.ssh/id_rsa

# Get the latest tar file from Nexus
echo "Retrieving the latest TAR file ($FILE) from Nexus" >&2
rm -f $FILE > /dev/null 2>&1
${WGET} -nv http://nexus.networkfleet.com:8081/nexus/content/repositories/snapshots/com/networkfleet/api-docs/${VERSION}/$FILE

if [ ! -f $FILE ]; then
  echo "Failed to retrieve $FILE from Nexus" >&2
  exit 1;
fi

for HOST in apache1-stage apache2-stage; do
  echo "Copying $FILE file to $HOST"
  cat $FILE | $SSH -i $KEY $HOST > ssh.log 2>&1
  if [ $? -ne 0 ]; then
    echo "There was a problem with ssh. Check the log file at $PWD/ssh.log"  >&2
    exit 2;
  fi
done

exit 0
