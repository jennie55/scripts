#!/bin/bash
# Specify the environment variable for this NWF microservice app

#Script variables
export APP_NAME=api-weather-webapp
export APP_JAR=${APP_NAME}.jar
JMX_PORT=1096
PORT_NUMBER=6600
export JAVA_HOME="/usr/java/latest"

HOST_NAME=$(hostname)
JMX_OPTIONS="-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=${JMX_PORT}"
JMX_OPTIONS="${JMX_OPTIONS} -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false"
JMX_OPTIONS="${JMX_OPTIONS} -Djava.rmi.server.hostname=${HOST_NAME}"

JVM_OPTIONS="-Dis=${APP_NAME}"
JVM_OPTIONS="${JVM_OPTIONS} -Xmx1280m"
JVM_OPTIONS="${JVM_OPTIONS} -Duser.timezone=GMT"
JVM_OPTIONS="${JVM_OPTIONS} -Djava.security.egd=file:/dev/./urandom"
JVM_OPTIONS="${JVM_OPTIONS} $JMX_OPTIONS"
export JVM_OPTIONS="${JVM_OPTIONS}"

## Note expecting the full path in BASE_PATH
SPRING_PID_FILE="${BASE_PATH}/${APP_NAME}.pid"
SPRING_LOG_PREFIX="${BASE_PATH}/logs/${APP_NAME}"

SPRING_OPTIONS="--server.port=${PORT_NUMBER}"
SPRING_OPTIONS="${SPRING_OPTIONS} --spring.pid.file=${SPRING_PID_FILE}"
SPRING_OPTIONS="${SPRING_OPTIONS} --logging.file=${SPRING_LOG_PREFIX}"
export SPRING_OPTIONS="${SPRING_OPTIONS}"

#echo "JVM_OPTIONS = ${JVM_OPTIONS}"
#echo "SPRING_OPTIONS = ${SPRING_OPTIONS}"