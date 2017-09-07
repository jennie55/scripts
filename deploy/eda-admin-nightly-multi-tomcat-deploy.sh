#!/bin/sh

SCP=/usr/bin/scp
SSH=/usr/bin/ssh
CWD=`pwd`
RM=/usr/bin/rm
SLEEP=/bin/sleep
VERSION=NIGHTLY-SNAPSHOT

JAVA_HOME=/usr/java/jdk1.7.0_79
M2_HOME=/usr/local/teamcity-data/apache-maven-3.1.1
PATH=$PATH:$M2_HOME/bin
MAVEN_OPTS=-XX:MaxPermSize=512m

HOST="eda-admin-nightly"
TOMCAT_APP_LIST="admin activation"

# Stop eda
echo "Stopping Tomcat on eda-admin-nightly.networkfleet.com"
${SSH} eda@eda-admin-nightly.networkfleet.com "cd ~;./stop_all.sh"
STOPEXIT=$?
if [ $STOPEXIT -ne 0 ]; then
    echo "There was a problem stopping Tomcat on eda-admin-nightly.networkfleet.com. "
    exit $STOPEXIT                                    
fi

for tomcat_app in $TOMCAT_APP_LIST; do
    
    TOMCAT_ROOT=/usr/local/eda/tomcat_$tomcat_app
    
    # Clear out old extracted WAR
    #${SLEEP} 60 
    echo "Removing old extracted WAR on eda-admin-nightly.networkfleet.com for $TOMCAT_ROOT"
    ${SSH} eda@eda-admin-nightly.networkfleet.com "${RM} -rf ${TOMCAT_ROOT}/webapps/eda-admin-${VERSION}" > clean.log 2>&1
    CLEANEXIT=$?
    if [ $CLEANEXIT -ne 0 ]; then
	echo "There was a problem removing the old extracted WAR. Check the log file at ${CWD}/clean.log"
	exit $CLEANEXIT
    fi

    # Rename the current war
    echo "Renaming current jar file on eda-admin-nightly.networkfleet.com for $TOMCAT_ROOT"
    ssh eda@eda-admin-nightly.networkfleet.com "mv ${TOMCAT_ROOT}/webapps/eda-admin-${VERSION}.war ${TOMCAT_ROOT}/webapps/eda-admin-${VERSION}.war.old"
    # Copy over the latest war file to eda; Teamcity will ensure it is present
    echo "Copying over latest war file for $TOMCAT_ROOT on eda-admin-nightly.networkfleet.com"
    ${SCP} ./eda-admin-${VERSION}.war eda@eda-admin-nightly.networkfleet.com:${TOMCAT_ROOT}/webapps > scp.log
    SCPEXIT=$?
    if [ $SCPEXIT -ne 0 ]; then
	echo "There was a problem with scp. Check the log file at ${CWD}/scp.log"
	exit $SCPEXIT
    fi

done

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
echo "Starting Tomcat on eda-admin-nightly.networkfleet.com"
${SSH} eda@eda-admin-nightly.networkfleet.com "cd ~;./start_all.sh" > start.log
STARTEXIT=$?
if [ $STARTEXIT -ne 0 ]; then
echo "There was a problem starting Tomcat on eda-admin-nightly.networkfleet.com. Check the log file at ${CWD}/start.log"
exit $STARTEXIT
fi

exit 0
