#!/bin/bash

# This script checks all the Git projects on the release branch
# and runs git log to compare develop to the release branch.
# Any commits that are reported have not been merged to develop yet,
# so verify that everything is merged before starting the next branch.


# verify branch was specified on the command line
if [ -z "$1" ]
  then
    echo "must specify branch, for example: $0 2016.R17";exit 1
fi
branch=$1

mydir=`pwd`
gitlogfile="/usr/local/teamcity-data/tmp/unmerged.log"

rm $gitlogfile

#  --------------------------------------------------------------------
# get the project list from git:/parent/branch_projectlist
tempdir="/tmp/tmp_branchlist"

if [ -d "$tempdir" ]; then rm -rf $tempdir; fi

git clone ssh://git@git-corp.networkfleet.com:7999/nwf/parent.git $tempdir
cd $tempdir 
git checkout release/$branch
cd ..
source $tempdir/branch_projectlist
rm -rf $tempdir
#  --------------------------------------------------------------------


# loop through the list of Git projects
nogitlogchanges="true"
echo "====================================================" >> $gitlogfile
echo "  GIT $branch COMMITS UNMERGED TO DEVELOP" >> $gitlogfile
echo "====================================================" >> $gitlogfile
for project in ${GIT_PROJECTS[@]}; do
  echo "=======GIT $project================================="
  git_server="ssh://git@git-corp.networkfleet.com:7999"
  git_path=$project
  git_project=`dirname $git_path`
  git_repo=`basename $git_path`
  git_branch=`echo $branch | sed 's/REL_//'`
  git_tmpdir="/tmp/tmp_$git_repo"
  if [ -d "$git_tmpdir" ]; then rm -rf $git_tmpdir; fi
  git clone $git_server/$git_project/$git_repo.git $git_tmpdir -b release/$git_branch
  error=$?
  if [ $error -ne 0 ]; then
    echo "Error retrieving repo, verify branch exists"
    exit 0
  fi
  pushd . > /dev/null
  cd $git_tmpdir
  git checkout develop
  git pull 
  git checkout release/$git_branch 
  pwd
  
  # get change log for this Git project
  #  compare develop to the release branch
  BOTTOM_REV="develop"
  count=`git log $BOTTOM_REV..HEAD | grep commit | wc -l`
  if [[ "$count" -gt  "0" ]]; then
    nogitlogchanges="false"
    echo "====================================================" >> $gitlogfile
    echo $project >> $gitlogfile
    echo "--------------------------" >> $gitlogfile
    git log $BOTTOM_REV..HEAD  >> $gitlogfile
  fi

  popd > /dev/null
  rm -rf $git_tmpdir
done

if [ $nogitlogchanges = true ]; then
  echo "No unmerged commits on Branch $branch " >> $gitlogfile
fi

exit
