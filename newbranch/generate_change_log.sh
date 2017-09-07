#!/bin/bash

# check for commits in the last 24 hours 
# 

# verify branch was specified on the command line
if [ -z "$1" ]
  then
    echo "must specify branch, for example: $0 2016.R17";exit 1
fi
branch=$1


# get log file timeframe from command line 
if [ -z "$2" ]
then
  echo "Default log time = 24 hours";loghours=24
else
  echo "Log time = $2 hours";loghours=$2
fi


# need lockfile to ensure only one instance of the script is running
lockdir=/tmp/myscript.lock
if mkdir "$lockdir"
then    # directory did not exist, but was created successfully
  echo >&2 "successfully acquired lock: $lockdir"
     # continue script
else
  while [ -d "$lockdir" ]; do
    echo "waiting for lock" 
    sleep 60
  done 
  echo "acquired lock: $lockdir"  
  mkdir "$lockdir"
fi


# make sure the log file name is branch-specific 
mydir=`pwd`
gitlogfile="/usr/local/teamcity-data/tmp/change_$branch.log"
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
echo "========================================================================" >> $gitlogfile
echo "   Branch commits, last $loghours hours" >> $gitlogfile
echo "========================================================================" >> $gitlogfile
for project in ${GIT_PROJECTS[@]}; do
  echo "=======GIT $project======="
  git_server="ssh://git@git-corp.networkfleet.com:7999"
  git_path=$project
  git_project=`dirname $git_path`
  git_repo=`basename $git_path`
  git_branch=$branch
  git_tmpdir="/tmp/tmp_$git_repo"
  if [ -d "$git_tmpdir" ]; then rm -rf $git_tmpdir; fi
  git clone $git_server/$git_project/$git_repo.git $git_tmpdir -b release/$git_branch
  error=$?
  if [ $error -ne 0 ]; then
    echo "Error retrieving repo, verify branch exists"
    exit 1 
  fi
  pushd . > /dev/null
  cd $git_tmpdir
  git checkout develop
  git pull 
  git checkout release/$git_branch 
  pwd
  
  # get change log for this Git project
  count=`git log --since=$loghours.hours | grep commit | wc -l`
  if [[ "$count" -gt  "0" ]]; then
    nogitlogchanges="false"
    echo "          " >> $gitlogfile
    echo "-----------------------------" >> $gitlogfile
    echo " $project" >> $gitlogfile
    echo "-----------------------------" >> $gitlogfile
    #git log --since=$loghours.hours >> $gitlogfile
    git log --stat --no-merges --pretty=format:"%h%x09%an%x09%ad%x09%s" --since=$loghours.hours >> $gitlogfile
    echo "          " >> $gitlogfile
  fi

  popd > /dev/null
  rm -rf $git_tmpdir
done

if [ $nogitlogchanges = true ]; then
  echo "No Git changes on Branch $branch " >> $gitlogfile
fi

# release the lock 
rm -rf "$lockdir"
echo "released lock: $lockdir"

exit
