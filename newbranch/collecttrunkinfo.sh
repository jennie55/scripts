#!/bin/bash

# script to bump all pom versions on SVN branch, and generate the delta log file

# verify branch was specified on the command line
if [ -z "$1" ]
  then
    echo "must specify branch, for example: $0 REL_2016.R12";exit 1
fi

branch=$1

mydir=`pwd`
tempdir="/tmp/tmp_projlistcheckout_$branch"
repo="https://svn.networkfleet.com/repos/ted3"


# empty checkout of ted3
if [ -d "$tempdir" ]; then
  cd $tempdir
  svn update
else
  svn checkout $repo $tempdir --depth empty
  cd $tempdir
  # test if branch name is valid
  svn list $repo/parent/branches/$branch &> /dev/null
  error=$?
  if [ $error -ne 0 ]; then
    echo "branch "$branch" is not valid"
    cd $mydir
    rm -rf $tempdir
    exit 1
  fi
fi

# get list of projects on the branch
projectlist=()
for trunkproject in `svn list --depth immediates`
do
  trunkproject=${trunkproject%/}
  svn list $repo/$trunkproject/branches/$branch &> /dev/null
  error=$?
  if [ $error -eq 1 ]; then
    projectlist+=($trunkproject)
  fi
done

cd $mydir


for project in "${projectlist[@]}"
do
  lastcommit=`svn log $repo/$project -q -l 1| sed -e "s/[\-]//g"`
  lastcommitdate=`echo $lastcommit | awk '{print $5}'`
  lastcommitter=`echo $lastcommit | awk '{print $3}'`
  firstcommit=`svn log $repo/$project -q -r 1:HEAD --limit 1 | sed -e "s/[\-]//g"`
  firstcommitdate=`echo $firstcommit| awk '{print $5}'`
  firstcommitter=`echo $firstcommit | awk '{print $3}'`
  commitcount=`svn log $repo/$project -q | sed -e "s/[\-]//g" |grep r| wc -l`
  committerlist=`svn log $repo/$project -q | grep "^r" | awk '{print $3}' | sort -u`
  allcommitters=`for c in $committerlist; do echo "$c,"|tr -d '\n'; done` 
  cleanallcommitters=`echo $allcommitters | rev | cut -c 2- | rev`

  echo "$project;$firstcommitdate;$firstcommitter;$lastcommitdate;$lastcommitter;$commitcount;$cleanallcommitters"
done > outputfile


rm -rf $tempdir
