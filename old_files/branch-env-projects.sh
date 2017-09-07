#!/bin/bash

set -e

NEW_SNAPSHOT_VERSION='3.38.0-SNAPSHOT'
PAUSE_BETWEEN_BRANCHES=false

declare -a projects=(
  'api-management-env'
  'api-server-env'
  'arch-env'
  'dataconnect-env'
  'dataservice-env'
  'eda-alertengine-env'
  'eda-common-env'
  'eda-jjk-env'
  'eda-message-processor-env'
  'jjkeller-env'
  'oauth2-authorization-server-env'
  'ssp-env'
)

SVN_BASE='https://svn.networkfleet.com/repos/ted3'
PROJECTS_DIR='branch-env-projects'

if [ $(uname -o) == "Cygwin" ]; then
  # FIXES PATH ISSUE WHEN USING CYGWIN, MAVEN AND SVN
  WIN_SVN='C:\Program Files\CollabNet\Subversion Client\'
  PATH="${WIN_SVN}:${PATH}"
fi

delete_branches(){

  for project in ${projects[@]}; do
    branch_url="${SVN_BASE}/${project}/branches/prod"
    svn delete "${branch_url}" -m"deleting prod branch for ${project}"
  done
}

create_branches(){

  rm -rf "${PROJECTS_DIR}"
  svn co -r HEAD "${SVN_BASE}" "${PROJECTS_DIR}" --depth empty

  pushd "${PROJECTS_DIR}"

  for project in ${projects[@]}; do

    project_url="${SVN_BASE}/${project}"
    
    rm -rf "${project}"

    svn update "${project}" --depth empty
    svn update "${project}/branches" --depth empty
    svn update "${project}/trunk" --depth infinity
    svn cleanup

    pushd "${project}/trunk"

    mvn release:branch --batch-mode -DbranchName=prod \
                                    -DupdateBranchVersions=true \
                                    -DupdateWorkingCopyVersions=false \
                                    -DreleaseVersion=${NEW_SNAPSHOT_VERSION} \
                                    #-DdryRun=true

    [[ "${PAUSE_BETWEEN_BRANCHES}" = true ]] && { read -p 'Press [Enter] key to continue...'; }

    popd
  done

  popd
}

#delete_branches
#create_branches
