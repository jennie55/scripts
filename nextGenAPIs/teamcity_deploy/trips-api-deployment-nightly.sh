#!/bin/bash

#Script to deploy the trips-api project to nightly machines.

TARGET_APP_PID_FILE=trips-api-app.pid
ARTIFACT=trips-api-NIGHTLY-SNAPSHOT.jar
REMOTE_ARTIFACT_NAME=trips-api
REMOTE_ARTIFACT_EXTENSION=.jar
REMOTE_ARTIFACT_FULLNAME=${REMOTE_ARTIFACT_NAME}${REMOTE_ARTIFACT_EXTENSION}
START_STOP_SCRIPT=trips-api-start-stop.sh
TARGET_HOSTS=( tomcat@mservice1-nightly tomcat@mservice2-nightly )
TARGET_FOLDER=/usr/local/tomcat/temp
TARGET_CONTAINER_FOLDER=/usr/local/tomcat/spring-boot-app-trips
TARGET_CONTAINER_DEPLOYMENT_FOLDER=${TARGET_CONTAINER_FOLDER}
CURRENT_DATE_TIME=$(date +%Y-%m-%dT%T)
STOP_CONTAINER_COMMAND="cd ${TARGET_CONTAINER_FOLDER}; ./trips-api-start-stop.sh stop"
START_CONTAINER_COMMAND="cd ${TARGET_CONTAINER_FOLDER}; ./trips-api-start-stop.sh start port=8080"
BACKUP_REMOTE_ARTIFACT_COMMAND="cd ${TARGET_CONTAINER_FOLDER}; mv trips-api.jar ../temp/trip-api-${CURRENT_DATE_TIME}.jar"
CLEAN_REMOTE_DEPLOYMENT_FOLDER_COMMAND="cd ${TARGET_CONTAINER_FOLDER}; rm -rf trips-api*"
COPY_REMOTE_ARTIFACT_TO_DEPLOYMENT_COMMAND="cd /usr/local/tomcat/temp; mv trips-api.jar ${TARGET_CONTAINER_DEPLOYMENT_FOLDER}"

echo -e "\nMAKING A LOCAL COPY OF THE ARTIFACT"
echo -e "from:${ARTIFACT} to:${REMOTE_ARTIFACT_FULLNAME}"
cp -v ${ARTIFACT} ${REMOTE_ARTIFACT_FULLNAME}
echo "DONE"

for TARGET_HOST in ${TARGET_HOSTS[@]}
do

	echo -e "\nVERIFYING IF TARGET MACHINE HAS THE APPLICATION DEPLOYMENT FOLDER"
	echo "${TARGET_HOST}: test -e ${TARGET_CONTAINER_DEPLOYMENT_FOLDER}"
	ssh "${TARGET_HOST}" "test -e ${TARGET_CONTAINER_DEPLOYMENT_FOLDER}"
	if [[ $? -eq 0 ]]; then
	   echo "Remote deployment folder exists. Continue with deployment.";
	else
	   echo "Remote deployment folder does not exists. Creating the folder now.";
	   ssh "${TARGET_HOST}" "mkdir ${TARGET_CONTAINER_DEPLOYMENT_FOLDER}" > start.log 2>&1
	   [[ $? -eq 0 ]] || { echo "Error creating remote deployment folder."; cat start.log; exit 1; }
	fi
	echo "DONE"

	echo -e "\nCOPYING ARTIFACT TO TARGET MACHINE"
	echo "${REMOTE_ARTIFACT_FULLNAME} to:${TARGET_HOST}:${TARGET_FOLDER}"
	rsync --progress ${REMOTE_ARTIFACT_FULLNAME} ${TARGET_HOST}:${TARGET_FOLDER}
	[[ $? -eq 0 ]] || { echo "Deployment failed. Cannot rsync ${REMOTE_ARTIFACT_FULLNAME} to ${TARGET_HOST}:${TARGET_FOLDER}"; exit 1; }
	echo "Finished copying artifact"
	
	echo -e "\nSTOPING APPLICATION ON ${TARGET_HOST}." 
	echo "${STOP_CONTAINER_COMMAND}"
        ssh "${TARGET_HOST}" "test -e ${TARGET_CONTAINER_DEPLOYMENT_FOLDER}/${TARGET_APP_PID_FILE}"
        if [[ $? -eq 0 ]]; then
	   ssh "${TARGET_HOST}" "${STOP_CONTAINER_COMMAND}" > start.log 2>&1
	   [[ $? -eq 0 ]] || { echo "Error stoping application."; cat start.log; exit 1; }
        else
           { echo "Remote application is not running. Stop command not executed.";}
        fi
	echo "Finished stoping application"
	echo "Sleeping for 15 seconds"
	sleep 15
	echo "Finished sleeping for 15 seconds"
	
	echo -e "\nBACKING UP REMOTE ARTIFACT"
	echo "${TARGET_HOST}: ${BACKUP_REMOTE_ARTIFACT_COMMAND}"
	ssh "${TARGET_HOST}" "test -e ${TARGET_CONTAINER_DEPLOYMENT_FOLDER}/${REMOTE_ARTIFACT_FULLNAME}"
	if [[ $? -eq 0 ]]; then
	   ssh "${TARGET_HOST}" "${BACKUP_REMOTE_ARTIFACT_COMMAND}" > start.log 2>&1
	   [[ $? -eq 0 ]] || { echo "Error backing up remote artifact."; cat start.log; exit 1; }
	else
	   { echo "Remote file does not exist. Backup not executed.";}
	fi
	echo "DONE"
	
	echo -e "\nCLEANING DEPLOYMENT FOLDER"
	echo "${TARGET_HOST}: ${CLEAN_REMOTE_DEPLOYMENT_FOLDER_COMMAND}"
	ssh "${TARGET_HOST}" "test -e ${TARGET_CONTAINER_DEPLOYMENT_FOLDER}/"
	if [[ $? -eq 0 ]]; then
	   ssh "${TARGET_HOST}" "${CLEAN_REMOTE_DEPLOYMENT_FOLDER_COMMAND}" > start.log 2>&1
	   [[ $? -eq 0 ]] || { echo "Error cleaning remote artifact deployment folder."; cat start.log; exit 1; }
	else
	   { echo "Remote folder does not exist. Folder was not deleted.";}
	fi
	echo "DONE"
	
	echo -e "\nCOPYING ARTIFACT FROM REMOTE TEMP TO DEPLOYMENT FOLDER"
	echo "${TARGET_HOST}: ${COPY_REMOTE_ARTIFACT_TO_DEPLOYMENT_COMMAND}"
	ssh "${TARGET_HOST}" "${COPY_REMOTE_ARTIFACT_TO_DEPLOYMENT_COMMAND}" > start.log 2>&1
	[[ $? -eq 0 ]] || { echo "Error moving remote artifact to webapps folder."; cat start.log; exit 1; }
	echo "DONE"

        echo -e "\nCOPYING START/STOP SCRIPT TO TARGET MACHINE"
	echo "${START_STOP_SCRIPT} to:${TARGET_HOST}:${TARGET_CONTAINER_DEPLOYMENT_FOLDER}"
	rsync --progress ${START_STOP_SCRIPT} ${TARGET_HOST}:${TARGET_CONTAINER_DEPLOYMENT_FOLDER}
	[[ $? -eq 0 ]] || { echo "Deployment of script failed. Cannot rsync ${START_STOP_SCRIPT} to ${TARGET_HOST}:${TARGET_CONTAINER_DEPLOYMENT_FOLDER}"; exit 1; }
        ssh "${TARGET_HOST}" "cd ${TARGET_CONTAINER_DEPLOYMENT_FOLDER}; chmod 755 ${START_STOP_SCRIPT}" > start.log 2>&1
        [[ $? -eq 0 ]] || { echo "Deployment of script failed. Error setting script file permission in the remote host."; exit 1; }
	echo "Finished copying script artifact"
	
	echo -e "\nSTARTING APPLICATION ON ${TARGET_HOST}"
	echo "${START_CONTAINER_COMMAND}"
	ssh "${TARGET_HOST}" "${START_CONTAINER_COMMAND}" > start.log 2>&1
	[[ $? -eq 0 ]] || { echo "Error starting application."; cat start.log; exit 1; }
	echo "Finished starting application"

	echo -e "\n------------ DONE WITH DEPLOYMENT TO ${TARGET_HOST} ------------"

done