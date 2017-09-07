#!/bin/sh

usage()
{
        echo "Usage: $0 newbranch"
	echo "Example: $0 2016.R17"
}

usage_and_exit()
{
        usage
        exit $1
}

warning()
{
        echo -e "$@" 1>&2
        EXITCODE=`expr $EXITCODE + 1`
}

EXITCODE=0


# We list web last so the footer will show the latest rev number


#  --------------------------------------------------------------------
# get the project list from git:/parent/branch_projectlist
tempdir="/tmp/tmp_branchlist"

if [ -d "$tempdir" ]; then rm -rf $tempdir; fi
    
git clone ssh://git@git-corp.networkfleet.com:7999/nwf/parent.git $tempdir
cd $tempdir
git checkout develop 
cd ..
source $tempdir/branch_projectlist
rm -rf $tempdir
#  --------------------------------------------------------------------

if [ $# -ne 1 ]; then
        warning "Exactly one argument must be supplied."
	usage_and_exit
fi

branch=$1

if [ ${branch} = "develop" ]; then
    warning "Invalid destination. ${branch} is invalid."
fi

if [ $EXITCODE -gt 0 ]; then
        usage_and_exit $EXITCODE
fi


#------------ create release branch in Git repositories------------------

for project in ${GIT_PROJECTS[@]}; do
  echo "===============GIT $project============="
  git_server="ssh://git@git-corp.networkfleet.com:7999"
  git_path=$project
  git_project=`dirname $git_path`
  git_repo=`basename $git_path`
  git_branch=$branch
  git_tmpdir="/tmp/tmp_$git_repo"
  if [ -d "$git_tmpdir" ]; then rm -rf $git_tmpdir; fi
  git clone $git_server/$git_project/$git_repo.git $git_tmpdir -b develop
  error=$?
  if [ $error -ne 0 ]; then
    echo "Error retrieving repository"
    exit 0
  fi
  pushd . > /dev/null
  cd $git_tmpdir
  
  git branch release/$git_branch
  git checkout release/$git_branch
  git push -u origin release/$git_branch
  error=$?
  if [ $error -ne 0 ]; then
    echo "Error pushing to Git repo, check permissions"
    exit 0
  fi
  popd > /dev/null
  rm -rf $git_tmpdir
done

#---------------------end Git branches----------------------------------

exit 0
