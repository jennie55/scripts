#!/bin/sh
# $URL: https://svn.networkfleet.com/repos/ted3/tools/trunk/ted3build.sh $
# $Id: ted3build.sh 11092 2012-04-26 18:19:21Z bjohnson $
# who:   kevin palmer
# why:   automate application build process
# when:  created 6/23/11
# updates:
#        added ability to build EDA
#        10/20, bwj:    modify eda project values
#                       cd to correct dir to build message-processor
#                       add build profile to portal war filename
#                4/24/2012, bwj: simplify EDA project layout (NWF-6973)
#                       include media build
#        4/26/2012, bwj: report multiple errors

usage()
{
  echo -e "usage: $0 --path [branches | tags | trunk]  --name [branch or tag name]  --rev [revision]  --profile [profile]  --eda" 
  echo -e "\t'--path' required; '--name' required unless path == 'trunk'; '--rev' optional (defaults to 'HEAD') '--profile' required"
  echo -e "\t'--eda' optional; '--path' must be one of 'branches' 'tags' or 'trunk';"
  echo -e "\t'--ws' optional; '--path' must be one of 'branches' 'tags' or 'trunk';"
  echo -e "\t'--name', '--rev', and '--profile' must contain only letters, numbers, periods, underscores, hyphens, or pound signs"
}

usage_and_exit()
{
  usage
  exit $1
}
  
warning()
{
  echo "$@" 1>&2
  EXITCODE=`expr $EXITCODE + 1`
} 

EXITCODE=0
BASE=`pwd`
BUILD_FAIL=""
SVN_ROOT="https://svn.networkfleet.com/repos/ted3"
JAVA_SSP=/usr/java/latest_1.7
ANT_SCRIPT="${BASE}/antbuild.sh"
BUILD_PATH=""
BRANCH_NAME=""
BUILD_REV=""
BUILD_PROFILE=""
EDA_FLAG=""
WS_FLAG=""
PROJECT_PATH=""
    
if [ "$#" -lt "4" ]; then
  # fewer than 4 arguments supplied
  warning "too few arguments"
else
  # at least 4 arguments supplied; make sure they are sufficient and valid
  
  while (( "$#" )); do
    case "$1" in
      "--path")
        BUILD_PATH="$2"
        shift 2
        ;;
      "--name")
        BRANCH_NAME="$2"
        shift 2
        ;;
      "--rev")
        BUILD_REV="$2"
        shift 2
        ;;
      "--profile")
        BUILD_PROFILE="$2"
        shift 2
        ;;
      "--eda")
        EDA_FLAG="Y"
        shift 1
        ;;
	  "--ws")
        WS_FLAG="Y"
        shift 1
        ;;
      *)
        warning "argument not recognized" $1
        break
        ;;
    esac

  done

  # '--path' is required
  if [ "$BUILD_PATH" != "branches" ] && [ "$BUILD_PATH" != "tags" ] && [ "$BUILD_PATH" != "trunk" ]; then
    warning "incorrect path"
  fi

  # '--name' is only required if '--path' is not "trunk"
  if [ "$BUILD_PATH" == "branches" ] || [ "$BUILD_PATH" == "tags" ]; then
    if [ "$BRANCH_NAME" == "" ]; then
      warning "incorrect name"
    fi
  elif [ "$BUILD_PATH" == "trunk" ]; then
    if [ "$BRANCH_NAME" != "" ]; then
      warning "branch name cannot be specified when path is 'trunk'"
    else
      # hack $BRANCH_NAME for proper directory traversing later in script
      BRANCH_NAME="trunk"
    fi
  fi
  if [ "$BRANCH_NAME" != "" ]; then
    if [[ $BRANCH_NAME =~ [^(a-zA-Z0-9)_\.\#-] ]]; then
      warning "name must contain only letters, numbers, periods, underscores, hyphens, or pound signs."
    fi
  fi

  # '--rev' is optional; defaults to 'HEAD'
  if [ "$BUILD_REV" == "" ]; then
    BUILD_REV="HEAD"
  else
    if [[ $BUILD_REV =~ [^(a-zA-Z0-9)_\.\#-] ]]; then
      warning "rev must contain only letters, numbers, periods, underscores, hyphens, or pound signs."
    fi
  fi

  # '--profile' is required
  if [ "$BUILD_PROFILE" == "" ]; then
    warning "incorrect profile"
  else
    if [[ $BUILD_PROFILE =~ [^(a-zA-Z0-9)_\.\#-] ]]; then
      warning "profile must contain only letters, numbers, periods, underscores, hyphens, or pound signs."
    fi
  fi

fi

if [ $EXITCODE -gt 0 ]; then
        # Limit exit status to common Unix practice
        test $EXITCODE -gt 125 && EXITCODE=125
        usage_and_exit $EXITCODE
fi

if [ ! -f $ANT_SCRIPT ]; then
        warning "$ANT_SCRIPT missing!"
        exit $EXITCODE
fi

#PROJECTS=( parent common model dataservice media restdocs-parent oauth2-parent api-common-parent api-model api-server api-client api-management testing ssp-web legacygateway portal)
#PROJECTS=( parent common model dataservice media portal testing ssp-web legacygateway)
#PROJECTS=( restdocs-parent api-common-parent api-model api-server api-client api-management testing )
PROJECTS=( 
#parent 
#testing 
#common 
#model 
#dataservice 
media 
#jjkeller
#ssp-web 
#nwffaces
#nwffaces-all
#legacygateway 
#portal
)

  
if [ "$EDA_FLAG" == "Y" ]; then
  PROJECTS=( ${PROJECTS[@]} eda-common eda-alertengine eda-console-webapp eda-message-processor 
  #dataconnect
  )
  
fi

if [ "$WS_FLAG" == "Y" ]; then
  PROJECTS=( ${PROJECTS[@]} webservice )
fi


for P in ${PROJECTS[@]}; do
  # clean up any old build dirs
  rm -rf ${P}-*

  # build project
  mkdir -p ${P}-${BUILD_PATH}
  cd ${P}-${BUILD_PATH}

  # thanks to shiny T for poor svn path naming
  if [ "$P" == "portal" ]; then
    PROJECT_PATH="web"
  else
    PROJECT_PATH="$P"
  fi

  if [ "$BUILD_PATH" == "trunk" ]; then
    svn co -r${BUILD_REV} ${SVN_ROOT}/${PROJECT_PATH}/${BUILD_PATH}
  else
    svn co -r${BUILD_REV} ${SVN_ROOT}/${PROJECT_PATH}/${BUILD_PATH}/${BRANCH_NAME}
  fi

  if [ "$?" -ne "0" ]; then
    BUILD_FAIL="$P"
    break
  fi

  cd ${BRANCH_NAME}

  case ${P} in

    media) 

      ${ANT_SCRIPT} -Dsrc.path=${BRANCH_NAME}-${BUILD_REV}-${BUILD_PROFILE}_profile;;

    ssp-web)

      #Need to run ssp with maven 3 and java 7
      CURRENT_JAVA=$JAVA_HOME;
      JAVA_HOME=$JAVA_SSP;

      echo "--------------------------------------------------------------------------------------------------"
      echo "--------------------------------------------------------------------------------------------------"
      echo "--------------------------------------------------------------------------------------------------"
      echo "/usr/local/maven/apache-maven-3.0.5/bin/mvn -U -P ${BUILD_PROFILE} clean install -DskipTests=true;"
      echo "--------------------------------------------------------------------------------------------------"
      echo "--------------------------------------------------------------------------------------------------"
      echo "--------------------------------------------------------------------------------------------------"
      /usr/local/maven/apache-maven-3.0.5/bin/mvn -U -P ${BUILD_PROFILE} clean install -DskipTests=true;
      JAVA_HOME=$CURRENT_JAVA;;

    api-server | api-common-parent | api-management | oauth2-parent) 
#
#      /usr/local/maven/apache-maven-3.0.5/bin/mvn -U -P ${BUILD_PROFILE} clean install -DskipTests=true;;
      /usr/local/maven/apache-maven-3.0.5/bin/mvn -U -P ${BUILD_PROFILE} -Ddeployment.env=${BUILD_PROFILE} clean install -DskipTests=true;;

    *)

      mvn -U -P ${BUILD_PROFILE} clean install -DskipTests=true;;

  esac

  if [ "$?" -ne "0" ]; then
    BUILD_FAIL="$P"
    break
  fi

  cd $BASE

done

if [ "$BUILD_FAIL" == "" ]; then
  mv portal-${BUILD_PATH}/${BRANCH_NAME}/target/nwf-portal.war nwf-portal-${BRANCH_NAME}-${BUILD_REV}-${BUILD_PROFILE}_profile.war
  mv media-${BUILD_PATH}/${BRANCH_NAME}/media-${BRANCH_NAME}-${BUILD_REV}-${BUILD_PROFILE}_profile.zip ${BASE}
#  mv api-server-${BUILD_PATH}/${BRANCH_NAME}/target/api-server*.war api-server-${BRANCH_NAME}-${BUILD_REV}-${BUILD_PROFILE}_profile.war
#  mv api-management-${BUILD_PATH}/${BRANCH_NAME}/target/api-management*.war api-management-${BRANCH_NAME}-${BUILD_REV}-${BUILD_PROFILE}_profile.war
#  mv oauth2-parent-${BUILD_PATH}/${BRANCH_NAME}/oauth2-authorization-server/target/oauth2-authorization-server*.war oauth2-authorization-server-${BRANCH_NAME}-${BUILD_REV}-${BUILD_PROFILE}_profile.war
  mv ssp-web-${BUILD_PATH}/${BRANCH_NAME}/target/ssp.war ssp-${BRANCH_NAME}-${BUILD_REV}-${BUILD_PROFILE}_profile.war
  
  if [ "$EDA_FLAG" == "Y" ]; then
    mv eda-alertengine-${BUILD_PATH}/${BRANCH_NAME}/target/alertengine-*.war alertengine-${BRANCH_NAME}-${BUILD_REV}-${BUILD_PROFILE}_profile.war
    mv eda-console-webapp-${BUILD_PATH}/${BRANCH_NAME}/target/eda-console-webapp.war eda-console-webapp-${BRANCH_NAME}-${BUILD_REV}-${BUILD_PROFILE}_profile.war
    mv eda-message-processor-${BUILD_PATH}/${BRANCH_NAME}/target/message-processor-*.war message-processor-${BRANCH_NAME}-${BUILD_REV}-${BUILD_PROFILE}_profile.war
#    mv dataconnect-${BUILD_PATH}/${BRANCH_NAME}/target/dataconnect-*.war dataconnect-${BRANCH_NAME}-${BUILD_REV}-${BUILD_PROFILE}_profile.war
#    mv dataconnect-${BUILD_PATH}/${BRANCH_NAME}/target/dataconnect-*.zip dataconnect-${BRANCH_NAME}-${BUILD_REV}-${BUILD_PROFILE}_profile-distribution.zip
  fi
  
  if [ "$WS_FLAG" == "Y" ]; then
    mv webservice-${BUILD_PATH}/${BRANCH_NAME}/target/webservice.war webservice-${BRANCH_NAME}-${BUILD_REV}-${BUILD_PROFILE}_profile.war
  fi
  
else
  echo "execution failed due to a problem with the $BUILD_FAIL project"
  exit 1
fi
