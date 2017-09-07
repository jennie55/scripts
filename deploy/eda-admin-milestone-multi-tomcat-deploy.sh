#!/bin/sh

SCP=/usr/bin/scp
SSH=/usr/bin/ssh
CWD=`pwd`
RM=/usr/bin/rm
SLEEP=/bin/sleep
VERSION=`grep version pom.xml |grep 3|head -1|cut -f 2 -d \<|cut -d \> -f 2`

for TOMCAT_ROOT in /usr/local/eda/tomcat_email /usr/local/eda/tomcat_activation; do

    # Stop eda
    echo "Stopping Tomcat MP on eda-admin-milestone.networkfleet.com for $TOMCAT_ROOT"
    ${SSH} eda@eda-admin-milestone.networkfleet.com "cd ${TOMCAT_ROOT}/bin;./shutdown.sh"
    STOPEXIT=$?
    if [ $STOPEXIT -ne 0 ]; then
	echo "There was a problem stopping Tomcat MP on eda-admin-milestone.networkfleet.com. "
	exit $STOPEXIT
    fi

    # Clear out old extracted WAR
    ${SLEEP} 120
    echo "Removing old extracted WAR on eda-admin-milestone.networkfleet.com for $TOMCAT_ROOT"
    ${SSH} eda@eda-admin-milestone.networkfleet.com "${RM} -rf ${TOMCAT_ROOT}/webapps/message-processor" > clean.log 2>&1
    CLEANEXIT=$?
    if [ $CLEANEXIT -ne 0 ]; then
	echo "There was a problem removing the old extracted WAR. Check the log file at ${CWD}/clean.log"
	exit $CLEANEXIT
    fi

    # Rename the current war
    echo "Renaming current jar file on eda-admin-milestone.networkfleet.com for $TOMCAT_ROOT"
    ssh eda@eda-admin-milestone.networkfleet.com "mv ${TOMCAT_ROOT}/webapps/message-processor.war ${TOMCAT_ROOT}/webapps/message-processor.war.old"
    # Copy over the latest war file to eda; Teamcity will ensure it is present
    echo "Copying over latest war file for $TOMCAT_ROOT on eda-admin-milestone.networkfleet.com"
    ${SCP} ./message-processor-${VERSION}.war eda@eda-admin-milestone.networkfleet.com:${TOMCAT_ROOT}/webapps/message-processor.war > scp.log
    SCPEXIT=$?
    if [ $SCPEXIT -ne 0 ]; then
	echo "There was a problem with scp. Check the log file at ${CWD}/scp.log"
	exit $SCPEXIT
    fi

    # Start eda
    echo "Starting Tomcat MP on eda-admin-milestone.networkfleet.com for $TOMCAT_ROOT"
    ${SSH} eda@eda-admin-milestone.networkfleet.com "cd ${TOMCAT_ROOT}/bin; export TOMCAT_PID=${TOMCAT_ROOT}/tomcat.pid;./startup.sh" > start.log
    STARTEXIT=$?
    if [ $STARTEXIT -ne 0 ]; then
	echo "There was a problem starting Tomcat MP on eda-admin-milestone.networkfleet.com. Check the log file at ${CWD}/start.log"
	exit $STARTEXIT
    fi
done

exit 0
