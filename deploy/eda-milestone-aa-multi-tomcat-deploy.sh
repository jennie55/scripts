#!/bin/sh

SCP=/usr/bin/scp
SSH=/usr/bin/ssh
JARDEST=/usr/local/eda/tomcat_AA/webapps
BINDEST=/usr/local/eda/tomcat_AA/bin
CWD=`pwd`
RM=/usr/bin/rm
SLEEP=/bin/sleep
VERSION=`grep version pom.xml |grep 3|head -1|cut -f 2 -d \<|cut -d \> -f 2`


for HOST in eda1-mile eda2-mile eda3-mile eda4-mile ; do

    # Stop eda
    echo "Stopping Tomcat AA on $HOST"
    ${SSH} eda@$HOST "cd ${BINDEST};./shutdown.sh"
    STOPEXIT=$?
    if [ $STOPEXIT -ne 0 ]; then
	echo "There was a problem stopping Tomcat AA on $HOST"
	exit $STOPEXIT
    fi

    # Clear out old extracted WAR
    ${SLEEP} 60
    echo "Removing old extracted WAR on $HOST"
    ${SSH} eda@$HOST "${RM} -rf ${JARDEST}/alertengine" > clean.log 2>&1
    CLEANEXIT=$?
    if [ $CLEANEXIT -ne 0 ]; then
	echo "There was a problem removing the old extracted WAR. Check the log file at ${CWD}/clean.log"
	exit $CLEANEXIT
    fi

    # Rename the current war
    echo "Renaming current jar file on $HOST"
    ssh eda@$HOST "mv ${JARDEST}/alertengine.war ${JARDEST}/alertengine.war.old"
    # Copy over the latest war file to eda; Teamcity will ensure it is present
    echo "Copying over latest war file to Tomcat AA on $HOST"
    ${SCP} ./alertengine-${VERSION}.war eda@$HOST:${JARDEST}/alertengine.war > scp.log
    SCPEXIT=$?
    if [ $SCPEXIT -ne 0 ]; then
	echo "There was a problem with scp. Check the log file at ${CWD}/scp.log"
	exit $SCPEXIT
    fi

    # Start eda
    echo "Starting Tomcat AA on $HOST"
    ${SSH} eda@$HOST "cd ${BINDEST};./startup.sh" > start.log
    STARTEXIT=$?
    if [ $STARTEXIT -ne 0 ]; then
	echo "There was a problem starting Tomcat AA on $HOST. Check the log file at ${CWD}/start.log"
	exit $STARTEXIT
    fi
done

exit 0
