#!/bin/bash

#Script to deploy the trips-api project to sanbox machine.

ARTIFACT=trips-api-NIGHTLY-SNAPSHOT.war
REMOTE_ARTIFACT_NAME=api.war
TARGET_HOST=bea@app2-sandbox
TARGET_FOLDER=/home/bea/tripsservice/tomcat_tripsservice/temp
CURRENT_DATE_TIME=$(date +%Y-%m-%dT%T)
STOP_CONTAINER_COMMAND="cd /home/bea/tripsservice/tomcat_tripsservice; ./bin/catalina.sh stop"
START_CONTAINER_COMMAND="cd /home/bea/tripsservice/tomcat_tripsservice; ./bin/catalina.sh start"
BACKUP_REMOTE_ARTIFACT_COMMAND="cd /home/bea/tripsservice/tomcat_tripsservice/webapps; mv api.war ../temp/api-${CURRENT_DATE_TIME}.war"
CLEAN_REMOTE_DEPLOYMENT_FOLDER_COMMAND="cd /home/bea/tripsservice/tomcat_tripsservice/webapps; rm -rf api"
COPY_REMOTE_ARTIFACT_TO_DEPLOYMENT_COMMAND="cd /home/bea/tripsservice/tomcat_tripsservice/temp; mv api.war ../webapps/"

echo -e "\nMAKING A LOCAL COPY OF THE ARTIFACT"
echo -e "from:${ARTIFACT} to:${REMOTE_ARTIFACT_NAME}"
cp ${ARTIFACT} ${REMOTE_ARTIFACT_NAME}
echo "DONE"

echo -e "\nCOPYING ARTIFACT TO TARGET MACHINE"
echo "${REMOTE_ARTIFACT_NAME} to:${TARGET_HOST}:${TARGET_FOLDER}"
rsync --progress ${REMOTE_ARTIFACT_NAME} ${TARGET_HOST}:${TARGET_FOLDER}
[[ $? -eq 0 ]] || { echo "Deployment failed. Cannot rsync ${ARTIFACT} to ${TARGET_HOST}:${TARGET_FOLDER}"; exit 1; }
echo "Finished copying artifact"

echo -e "\nSTOPING TOMCAT ON ${TARGET_HOST}." 
echo "${STOP_CONTAINER_COMMAND}"
ssh "${TARGET_HOST}" "${STOP_CONTAINER_COMMAND}" > start.log 2>&1
[[ $? -eq 0 ]] || { echo "Error stoping tomcat server."; exit 1; }
echo "Finished stoping Tomcat"
echo "Sleeping for 15 seconds"
sleep 15
echo "Finished sleeping for 15 seconds"

echo -e "\nBACKING UP REMOTE ARTIFACT"
echo "${TARGET_HOST}: ${BACKUP_REMOTE_ARTIFACT_COMMAND}"
ssh "${TARGET_HOST}" "${BACKUP_REMOTE_ARTIFACT_COMMAND}" > start.log 2>&1
[[ $? -eq 0 ]] || { echo "Error backing up remote artifact."; exit 1; }
echo "DONE"

echo -e "\nCLEANING DEPLOYMENT FOLDER"
echo "${TARGET_HOST}: ${CLEAN_REMOTE_DEPLOYMENT_FOLDER_COMMAND}"
ssh "${TARGET_HOST}" "${CLEAN_REMOTE_DEPLOYMENT_FOLDER_COMMAND}" > start.log 2>&1
[[ $? -eq 0 ]] || { echo "Error cleaning remote artifact deployment folder."; exit 1; }
echo "DONE"

echo -e "\nCOPYING ARTIFACT FROM REMOTE TEMP TO DEPLOYMENT FOLDER"
echo "${TARGET_HOST}: ${COPY_REMOTE_ARTIFACT_TO_DEPLOYMENT_COMMAND}"
ssh "${TARGET_HOST}" "${COPY_REMOTE_ARTIFACT_TO_DEPLOYMENT_COMMAND}" > start.log 2>&1
[[ $? -eq 0 ]] || { echo "Error moving remote artifact to webapps folder."; exit 1; }
echo "DONE"

echo -e "\nSTARTING TOMCAT SERVER ON ${TARGET_HOST}"
echo "${START_CONTAINER_COMMAND}"
ssh "${TARGET_HOST}" "${START_CONTAINER_COMMAND}" > start.log 2>&1
[[ $? -eq 0 ]] || { echo "Error stoping tomcat server."; exit 1; }
echo "Finished starting Tomcat server"