#!/bin/bash

usage() 
{ 
  echo -e "Usage: $0 --rev [revision]"; 
  echo -e "\t'--all' optional; deploys all projects"
  echo -e "\t'--portal' optional; in absense of --all, deploys the portal"
  echo -e "\t'--report' optional; in absense of --all, deploys to the report node"
  echo -e "\t'--api' optional; in absense of --all, deploys the api"
  echo -e "\t'--ssp' optional; in absense of --all, deploys the ssp"
  echo -e "\t'--media' optional; in absense of --all, deploys the media to the apache servers"
  exit 1; 
}

warning()
{
  echo "$@" 1>&2
  exit 1; 
}

DEPLOY_PORTAL_FLAG=""
DEPLOY_REPORT_FLAG=""
DEPLOY_API_FLAG=""
DEPLOY_SSP_FLAG=""
DEPLOY_MEDIA_FLAG=""
BUILD_REV=""

while (( "$#" )); do
  case "$1" in
    "--all")
      DEPLOY_PORTAL_FLAG="Y"
      DEPLOY_REPORT_FLAG="Y"
      DEPLOY_API_FLAG="Y"
      DEPLOY_SSP_FLAG="Y"
      DEPLOY_MEDIA_FLAG="Y"
      shift 1
      ;;
    "--portal")
      DEPLOY_PORTAL_FLAG="Y"
      shift 1
      ;;
    "--report")
      DEPLOY_REPORT_FLAG="Y"
      shift 1
      ;;
    "--api")
      DEPLOY_API_FLAG="Y"
      shift 1
      ;;
    "--ssp")
      DEPLOY_SSP_FLAG="Y"
      shift 1
      ;;
    "--media")
      DEPLOY_MEDIA_FLAG="Y"
      shift 1
      ;;
    "--rev")
      BUILD_REV="$2"
      shift 2
      ;;
    *)
      warning "argument not recognized" $1
      break
      ;;
  esac
done  

if [ "$BUILD_REV" == "" ]; then
    usage
fi

# Set up the weblogic envronment so we can use the weblogic.Deployer
/usr/local/bea/wlserver_10.3.5/server/bin/setWLSEnv.sh
#java -cp /usr/local/bea/wlserver_10.3.5/server/lib/weblogic.jar  weblogic.Deployer -adminurl http://starsky.networkfleet.com:7041 -user weblogic -password weblogic1 -listapps

WL_HOME=/usr/local/bea
WL1212_HOME=/usr/local/bea12.1.2
WL_JAR=${WL_HOME}/wlserver_10.3.5/server/lib/weblogic.jar
WL1212_JAR=${WL1212_HOME}/wlserver/server/lib/weblogic.jar

echo ----------------------------------------------

if [ "$DEPLOY_PORTAL_FLAG" == "Y" ]; then
    echo Deploying to Stage.
    TARGET_WAR=nwf-portal-REL_3.42-${BUILD_REV}-staging_profile.war
    DOMAIN_HOME=${WL_HOME}/domains11/stage

    if [ ! -f ${TARGET_WAR} ]; then
	warning "Unable to deploy portal. ${TARGET_WAR} does not exist."
    fi

    cp -p $TARGET_WAR ${DOMAIN_HOME}/deployments/nwf-portal.war
    scp -Cp $TARGET_WAR hutch:${DOMAIN_HOME}/deployments/nwf-portal.war

    java -cp ${WL_JAR} weblogic.Deployer -adminurl http://starsky.networkfleet.com:7041 -user weblogic -password weblogic1 -stop -name nwf-portal

    java -cp ${WL_JAR}  weblogic.Deployer -adminurl http://starsky.networkfleet.com:7041 -user weblogic -password weblogic1 -redeploy -name nwf-portal

    java -cp ${WL_JAR}  weblogic.Deployer -adminurl http://starsky.networkfleet.com:7041 -user weblogic -password weblogic1 -start -name nwf-portal

    echo Force Stopping Stage.
    pushd ${DOMAIN_HOME}
    ./stopPortal1.sh --force
    ssh hutch "source ~/.bash_profile; cd ${DOMAIN_HOME}; ./stopPortal2.sh --force"

    sleep 5s #sleep for a few secs to give weblogic a chance to let go of ports

    echo Restaring Stage.
    ./startPortal1.sh
    ssh hutch "source ~/.bash_profile; cd ${DOMAIN_HOME}; ./startPortal2.sh"
    popd
fi

echo ----------------------------------------------

if [ "$DEPLOY_REPORT_FLAG" == "Y" ]; then
    echo Deploying to Report Node.
    TARGET_WAR=nwf-portal-REL_3.42-${BUILD_REV}-staging_profile.war
    DOMAIN_HOME=${WL_HOME}/domains11/report

    if [ ! -f ${TARGET_WAR} ]; then
	warning "Unable to deploy report. ${TARGET_WAR} does not exist."
    fi

    scp -Cp ${TARGET_WAR} rep1-stage:${DOMAIN_HOME}/deployments/nwf-portal.war

    java -cp ${WL_JAR}  weblogic.Deployer -adminurl http://rep1-stage.networkfleet.com:7051 -user weblogic -password weblogic1 -stop -name nwf-portal

    java -cp ${WL_JAR}  weblogic.Deployer -adminurl http://rep1-stage.networkfleet.com:7051 -user weblogic -password weblogic1 -redeploy -name nwf-portal

    java -cp ${WL_JAR}  weblogic.Deployer -adminurl http://rep1-stage.networkfleet.com:7051 -user weblogic -password weblogic1 -start -name nwf-portal

    echo Force Stopping Report Node.
    ssh rep1-stage "source ~/.bash_profile; cd ${DOMAIN_HOME}; ./stopReport1.sh --force"

    sleep 5s #sleep for a few secs to give weblogic a chance to let go of ports

    echo Restaring Report Node.
    ssh rep1-stage "source ~/.bash_profile; cd ${DOMAIN_HOME}; ./startReport1.sh"
fi

echo ----------------------------------------------

if [ "$DEPLOY_API_FLAG" == "Y" ]; then
    echo Deploying to API.
    SERVER_WAR=api-server-stage-${BUILD_REV}-SNAPSHOT.war
    MANAGEMENT_WAR=api-management-stage-${BUILD_REV}-SNAPSHOT.war
    OAUTH2_AUTHSERVER_WAR=oauth2-authorization-server-stage-${BUILD_REV}-SNAPSHOT.war
    DOMAIN_HOME=${WL1212_HOME}/user_projects/domains/api

    if [ ! -f ${SERVER_WAR} ]; then
	warning "Unable to deploy api. ${SERVER_WAR} does not exist."
    fi
    if [ ! -f ${MANAGEMENT_WAR} ]; then
	warning "Unable to deploy api. ${MANAGEMENT_WAR} does not exist."
    fi
    if [ ! -f ${OAUTH2_AUTHSERVER_WAR} ]; then
	warning "Unable to deploy api. ${OAUTH2_AUTHSERVER_WAR} does not exist."
    fi

    cp -p ${SERVER_WAR} ${DOMAIN_HOME}/deployments/api-server-stage.war
    cp -p ${MANAGEMENT_WAR} ${DOMAIN_HOME}/deployments/api-management-stage.war
    cp -p ${OAUTH2_AUTHSERVER_WAR} ${DOMAIN_HOME}/deployments/oauth2-authorization-server-stage.war

    scp -Cp ${SERVER_WAR} hutch:${DOMAIN_HOME}/deployments/api-server-stage.war
    scp -Cp ${MANAGEMENT_WAR} hutch:${DOMAIN_HOME}/deployments/api-management-stage.war
    scp -Cp ${OAUTH2_AUTHSERVER_WAR} hutch:${DOMAIN_HOME}/deployments/oauth2-authorization-server-stage.war

    # STOP
    java -cp ${WL_JAR}  weblogic.Deployer -adminurl http://starsky.networkfleet.com:7045 -user weblogic -password weblogic1 -stop -name api-server
    java -cp ${WL_JAR}  weblogic.Deployer -adminurl http://starsky.networkfleet.com:7045 -user weblogic -password weblogic1 -stop -name api-management
    java -cp ${WL_JAR}  weblogic.Deployer -adminurl http://starsky.networkfleet.com:7045 -user weblogic -password weblogic1 -stop -name oauth2-authorization-server

    # REDEPLOY
    java -cp ${WL_JAR}  weblogic.Deployer -adminurl http://starsky.networkfleet.com:7045 -user weblogic -password weblogic1 -redeploy -name api-server
    java -cp ${WL_JAR}  weblogic.Deployer -adminurl http://starsky.networkfleet.com:7045 -user weblogic -password weblogic1 -redeploy -name api-management
    java -cp ${WL_JAR}  weblogic.Deployer -adminurl http://starsky.networkfleet.com:7045 -user weblogic -password weblogic1 -redeploy -name oauth2-authorization-server

    # START
    java -cp ${WL_JAR}  weblogic.Deployer -adminurl http://starsky.networkfleet.com:7045 -user weblogic -password weblogic1 -start -name api-server
    java -cp ${WL_JAR}  weblogic.Deployer -adminurl http://starsky.networkfleet.com:7045 -user weblogic -password weblogic1 -start -name api-management
    java -cp ${WL_JAR}  weblogic.Deployer -adminurl http://starsky.networkfleet.com:7045 -user weblogic -password weblogic1 -start -name oauth2-authorization-server


    echo Force Stopping API.
    pushd ${DOMAIN_HOME}
    ./stopApi1.sh --force
    ssh hutch "source ~/.bash_profile; cd ${DOMAIN_HOME}; ./stopApi2.sh --force"

    sleep 5s #sleep for a few secs to give weblogic a chance to let go of ports

    echo Restaring API.
    ./startApi1.sh
    ssh hutch "source ~/.bash_profile; cd ${DOMAIN_HOME}; ./startApi2.sh"
popd
fi

echo ----------------------------------------------

if [ "$DEPLOY_SSP_FLAG" == "Y" ]; then
    echo Deploying to SSP.
    TARGET_WAR=ssp-REL_3.42-${BUILD_REV}-staging_profile.war

    if [ ! -f ${TARGET_WAR} ]; then
	warning "Unable to deploy ssp. ${TARGET_WAR} does not exist."
    fi

    # Set up the weblogic envronment so we can use the weblogic.Deployer
    WL_HOME=/usr/local/bea12.1.2
    ${WL_HOME}/wlserver/server/bin/setWLSEnv.sh
    DOMAIN_HOME=${WL_HOME}/user_projects/domains/ssp_domain
    WL_JAR=${WL_HOME}/wlserver/server/lib/weblogic.jar

    java -cp ${WL_JAR}  weblogic.Deployer -adminurl http://starsky.networkfleet.com:7065 -user weblogic -password weblogic1 -listapps
    echo $?

    cp -p ssp-REL_3.42-${BUILD_REV}-staging_profile.war ${DOMAIN_HOME}/deployments/ssp.war
    scp -Cp ssp-REL_3.42-${BUILD_REV}-staging_profile.war hutch:${DOMAIN_HOME}/deployments/ssp.war

    java -cp ${WL_JAR}  weblogic.Deployer -adminurl http://starsky.networkfleet.com:7065 -user weblogic -password weblogic1 -stop -name ssp
    echo $?

    java -cp ${WL_JAR}  weblogic.Deployer -adminurl http://starsky.networkfleet.com:7065 -user weblogic -password weblogic1 -redeploy -name ssp
    echo $?

    java -cp ${WL_JAR}  weblogic.Deployer -adminurl http://starsky.networkfleet.com:7065 -user weblogic -password weblogic1 -start -name ssp
    echo $?

    echo Force Stopping SSP.
    pushd ${DOMAIN_HOME}
    ./stopSsp1.sh --force
    ssh hutch "source ~/.bash_profile; cd ${DOMAIN_HOME}; ./stopSsp2.sh --force"

    sleep 5s #sleep for a few secs to give weblogic a chance to let go of ports

    echo Restaring SSP.
    ./startSsp1.sh
    ssh hutch "source ~/.bash_profile; cd ${DOMAIN_HOME}; ./startSsp2.sh"
    popd
fi

echo ----------------------------------------------

if [ "$DEPLOY_MEDIA_FLAG" == "Y" ]; then
    echo Deploying Media.
    TARGET_ZIP=media-REL_3.42-${BUILD_REV}-staging_profile.zip

    if [ ! -f ${TARGET_ZIP} ]; then
	warning "Unable to deploy media. ${TARGET_ZIP} does not exist."
    fi

    scp -p ${TARGET_ZIP} static@apache1-stage:/tmp/${TARGET_ZIP}
    ssh static@apache1-stage "source ~/.bash_profile; cd /var/www/html.qa/media; unzip -o /tmp/${TARGET_ZIP}"
    ssh static@apache1-stage "source ~/.bash_profile; rm /tmp/${TARGET_ZIP}"
    
    scp -p ${TARGET_ZIP} static@apache2-stage:/tmp/${TARGET_ZIP}
    ssh static@apache2-stage "source ~/.bash_profile; cd /var/www/html.qa/media; unzip -o /tmp/${TARGET_ZIP}"
    ssh static@apache2-stage "source ~/.bash_profile; rm /tmp/${TARGET_ZIP}"
fi

echo ----------------------------------------------

