#!/bin/sh

SCP=/usr/bin/scp
SSH=/usr/bin/ssh
TOMCATHOME=/usr/local/eda/tomcat_console
WARDEST=webapps
CWD=`pwd`
RM=/usr/bin/rm
SLEEP=/bin/sleep

# Copy over the latest war file to tomcat; teamcity will ensure it is here
echo "Copying over latest war file to Tomcat"
${SCP} ./eda-console-webapp.war eda@eda-admin-milestone:${TOMCATHOME}/${WARDEST}/eda-console-webapp.war > scp.log
SCPEXIT=$?
if [ $SCPEXIT -ne 0 ]; then
  echo "There was a problem with scp. Check the log file at ${CWD}/scp.log" 
  exit $SCPEXIT
fi

# Stop tomcat
echo "Stopping Tomcat"
${SSH} eda@eda-admin-milestone "cd ${TOMCATHOME}/bin;./shutdown.sh" > stop.log 2>&1
STOPEXIT=$?
if [ $STOPEXIT -ne 0 ]; then
  echo "There was a problem stopping Tomcat. Check the log file at ${CWD}/stop.log" 
  exit $STOPEXIT
fi

# Clear out old extracted WAR
${SLEEP} 30
echo "Removing old extracted WAR"
${SSH} eda@eda-admin-milestone "${RM} -rf ${TOMCATHOME}/${WARDEST}/eda-console-webapp" > clean.log 2>&1
CLEANEXIT=$?
if [ $CLEANEXIT -ne 0 ]; then
  echo "There was a problem removing the old extracted WAR. Check the log file at ${CWD}/clean.log" 
  exit $CLEANEXIT
fi

# Start tomcat
echo "Starting Tomcat"
${SSH} eda@eda-admin-milestone "cd ${TOMCATHOME}/bin;./startup.sh" > start.log 2>&1
STARTEXIT=$?
if [ $STARTEXIT -ne 0 ]; then
  echo "There was a problem starting Tomcat. Check the log file at ${CWD}/start.log" 
  exit $STARTEXIT
fi

exit 0
