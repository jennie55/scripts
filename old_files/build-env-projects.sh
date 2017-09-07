#!/bin/bash

set -e

BRANCH='tags/rel3.40.0'
SKIP_TESTS=true
PAUSE_BETWEEN_BUILDS=false

declare -a projects=(
#  'parent'
#  'testing'
#  'common'
#  'model'
  'oauth2-parent'
  'dataconnect'
  'api-server'
  'api-client'
  'api-management'
  'dataservice-env'
  'dataconnect-env'
  'eda-jjk-env'
  'api-management-env'
  'api-server-env'
  'oauth2-authorization-server-env'
)

declare -a artifacts=(
  'api-management-env/api-management-stage/target/api-management-stage-*.war'
  'api-management-env/api-management-preprod/target/api-management-preprod-*.war'
  'api-management-env/api-management-prod/target/api-management-prod-*.war'
  'api-server-env/api-server-stage/target/api-server-stage-*.war'
  'api-server-env/api-server-preprod/target/api-server-preprod-*.war'
  'api-server-env/api-server-prod/target/api-server-prod-*.war'
  'dataconnect-env/dataconnect-staging/target/dataconnect-staging-*.war'
  'dataconnect-env/dataconnect-preprod/target/dataconnect-preprod-*.war'
  'dataconnect-env/dataconnect-prod/target/dataconnect-prod-*.war'
  'oauth2-authorization-server-env/oauth2-authorization-server-stage/target/oauth2-authorization-server-stage-*.war'
  'oauth2-authorization-server-env/oauth2-authorization-server-preprod/target/oauth2-authorization-server-preprod-*.war'
  'oauth2-authorization-server-env/oauth2-authorization-server-prod/target/oauth2-authorization-server-prod-*.war'
)

SVN_BASE='https://svn.networkfleet.com/repos/ted3'
PROJECTS_DIR='build-env-projects'
ARTIFACTS_DIR='artifacts'

mkdir -p "${ARTIFACTS_DIR}"
mkdir -p "${PROJECTS_DIR}"

checkout_projects(){

  pushd "${PROJECTS_DIR}"

  for project in ${projects[@]}; do
    rm -rf "${project}"
    svn co "${SVN_BASE}/${project}/${BRANCH}" "${project}"
  done

  popd
}

build_projects(){

  pushd "${PROJECTS_DIR}"

  for project in ${projects[@]}; do
    pushd "${project}"
    mvn clean install -DskipTests=${SKIP_TESTS}
    [[ "${PAUSE_BETWEEN_BUILDS}" = true ]] && { read -p 'Press [Enter] key to continue...'; }
    popd
  done

  popd
}

copy_artifacts(){

    for artifact in ${artifacts[@]}; do
      cp -pf ${PROJECTS_DIR}/${artifact} "${ARTIFACTS_DIR}"
    done
}

checkout_projects
build_projects
copy_artifacts
