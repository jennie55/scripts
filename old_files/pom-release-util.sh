#!/bin/bash

set -e

SVN_BASE='https://svn.networkfleet.com/repos/ted3'
BRANCH='branches/prod'
OLD_POM_VERSION='NIGHTLY-SNAPSHOT'

declare -a projects=(
allstate-ws
api-client
api-common-parent
api-grinder-test
api-management
api-model
api-server
api-test
arch
arch-dataservice
arch-model
cache-server
common
dataconnect
dataconnect-common
dataservice
dataservice-base
dms-dataservice
eda-alertengine
eda-common
eda-console-webapp
eda-jjk
eda-message-processor
eda-report-preprocessor
eda-tax
jjkeller
legacygateway
media
model
nwffaces-all
oauth2-parent
parent
report
restdocs-parent
rungps
rungps-web
ssp-web
testing
web
)


bump(){
  BRANCH=${1}
  NEW_POM_VERSION=${2}
  [[ -z ${NEW_POM_VERSION} ]] && { echo "bump requires an additional version arg, e.g, 3.32.0"; exit 1; }

  # CHECKOUT ROOT FOLDER WITH EMPTY DEPTH
  svn co ${SVN_BASE} ted3 --depth empty

  # FOR EACH PROJECT
  for project in "${projects[@]}"; do

    # IDENTIFY ALL THE POMS IN THE BRANCH
    poms=`svn list -R ${SVN_BASE}/${project}/${BRANCH} | grep pom.xml`

    # FOR EACH POM
    for pom in ${poms[@]}; do

      # IDENTIFY FILENAME OF POM
      filename="ted3/${project}/${BRANCH}/${pom}"

      # CHECKOUT POM
      svn update --parents "${filename}"

      # REPLACE VERSION IN POM
      sed -i 's|'"${OLD_POM_VERSION}"'|'"${NEW_POM_VERSION}"'|g' ${filename}

    done

  done
}

revert(){

  # from $SVN_HOME issue recursive revert
  svn revert -R *
}

status(){

  svn status ted3 | sed 's/^. *//g' | tee targets.txt
}

case "$1" in

  revert)  revert;;
  bump)    bump "$2" "$3";;
  status)  status;;
  *)       echo "Usage: $0 [revert|bump|status]" && exit 1

esac
