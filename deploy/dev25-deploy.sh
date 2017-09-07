#!/bin/sh

SCP=/usr/bin/scp
SSH=/usr/bin/ssh
JARDEST=/usr/local/bea/dev25/domains11/networkcar/networkcarserver
BINDEST=/usr/local/eda/tomcat_AA/bin
CWD=`pwd`
RM=/usr/bin/rm
SLEEP=/bin/sleep
VERSION=`grep version pom.xml |grep NIGHTLY|head -1|cut -f 2 -d \<|cut -d \> -f 2`

JAVA_HOME=/usr/java/jdk1.7.0_79
M2_HOME=/usr/local/teamcity-data/apache-maven-3.1.1
PATH=$PATH:$M2_HOME/bin
MAVEN_OPTS=-XX:MaxPermSize=512m

HOST_LIST="app1-nightly"
for HOST in $HOST_LIST; do
    # Stop weblogic
    echo "Stopping Dev25web $HOST"
    ${SSH} bea@$HOST "cd /usr/local/bea/dev25/domains11/networkcar;./stopNcNode1.sh --force"
    STOPEXIT=$?
    if [ $STOPEXIT -ne 0 ]; then
	echo "There was a problem stopping weblogic dev25web on $HOST"
	exit $STOPEXIT
    fi

    echo "Renaming current jar file on $HOST"
    ssh bea@$HOST "mv ${JARDEST}/NetworkCar.ear ${JARDEST}/NetworkCar.ear.old"
    # Copy over the latest war file to eda; Teamcity will ensure it is present
    echo "Copying over latest ear file  on $HOST"
    ${SCP} ./NetworkCar.ear bea@$HOST:${JARDEST} > scp.log
    SCPEXIT=$?
    if [ $SCPEXIT -ne 0 ]; then
	echo "There was a problem with scp. Check the log file at ${CWD}/scp.log"
	exit $SCPEXIT
    fi


    # Start weblogic
    echo "Starting Dev25web on $HOST"
    ${SSH} bea@$HOST "cd /usr/local/bea/dev25/domains11/networkcar;./startNcNode1.sh " > start.log
    STARTEXIT=$?
    if [ $STARTEXIT -ne 0 ]; then
	echo "There was a problem starting weblogic on $HOST. Check the log file at ${CWD}/start.log"
	exit $STARTEXIT
    fi
done

exit 0
