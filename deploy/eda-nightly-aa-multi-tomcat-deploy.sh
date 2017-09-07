#!/bin/sh

SCP=/usr/bin/scp
SSH=/usr/bin/ssh
JARDEST=/usr/local/eda/tomcat_AA/webapps
BINDEST=/usr/local/eda/tomcat_AA/bin
CWD=`pwd`
RM=/usr/bin/rm
SLEEP=/bin/sleep
VERSION=`grep version pom.xml |grep NIGHTLY|head -1|cut -f 2 -d \<|cut -d \> -f 2`

JAVA_HOME=/usr/java/jdk1.7.0_79
M2_HOME=/usr/local/teamcity-data/apache-maven-3.1.1
PATH=$PATH:$M2_HOME/bin
MAVEN_OPTS=-XX:MaxPermSize=512m

HOST_LIST="eda1-nightly eda2-nightly eda3-nightly eda4-nightly"
for HOST in $HOST_LIST; do
    # Stop eda
    echo "Stopping Tomcat AA on $HOST"
    ${SSH} eda@$HOST "cd ~;./stop_all.sh"
    STOPEXIT=$?
    if [ $STOPEXIT -ne 0 ]; then
	echo "There was a problem stopping Tomcat AA on $HOST"
	exit $STOPEXIT
    fi

    # Clear out old extracted WAR
    ${SLEEP} 60
    echo "Removing old extracted WAR on $HOST"
    ${SSH} eda@$HOST "${RM} -rf ${JARDEST}/alertengine-${VERSION}" > clean.log 2>&1
    CLEANEXIT=$?
    if [ $CLEANEXIT -ne 0 ]; then
	echo "There was a problem removing the old extracted WAR. Check the log file at ${CWD}/clean.log"
	exit $CLEANEXIT
    fi

    # Rename the current war
    echo "Renaming current jar file on $HOST"
    ssh eda@$HOST "mv ${JARDEST}/alertengine-${VERSION}.war ${JARDEST}/alertengine-${VERSION}.war.old"
    # Copy over the latest war file to eda; Teamcity will ensure it is present
    echo "Copying over latest war file to Tomcat AA on $HOST"
    ${SCP} ./alertengine-${VERSION}.war eda@$HOST:${JARDEST} > scp.log
    SCPEXIT=$?
    if [ $SCPEXIT -ne 0 ]; then
	echo "There was a problem with scp. Check the log file at ${CWD}/scp.log"
	exit $SCPEXIT
    fi

    # deploy properties files from SVN
    #   note that properties files for all apps on this box will be updated
    ssh eda@$HOST "rm ~/config-deployment*.war"
    ssh eda@$HOST "rm ~/eda-config-deploy*.war"
    mvn -U -q org.apache.maven.plugins:maven-dependency-plugin:2.8:copy -Dartifact=com.networkfleet:eda-config-deploy:NIGHTLY-SNAPSHOT:war -Dmdep.useBaseVersion=false -DoutputDirectory=.
    CONFIG_WARFILE=`ls eda-config-deploy*.war`
    echo "retrieved $CONFIG_WARFILE" 
    ${SCP} ./$CONFIG_WARFILE eda@$HOST:~ > scp.log
    SCPEXIT=$?
    if [ $SCPEXIT -ne 0 ]; then
    echo "There was a problem with copying the eda-config-deploy.war file. Check the log file at ${CWD}/scp.log"
     exit $SCPEXIT
    fi
    ssh eda@$HOST "./deploy_properties.py --warfile ~/$CONFIG_WARFILE"

    # Start eda
    echo "Starting Tomcat AA on $HOST"
    ${SSH} eda@$HOST "cd ~;./start_all.sh" > start.log
    STARTEXIT=$?
    if [ $STARTEXIT -ne 0 ]; then
	echo "There was a problem starting Tomcat AA on $HOST. Check the log file at ${CWD}/start.log"
	exit $STARTEXIT
    fi
done

exit 0
