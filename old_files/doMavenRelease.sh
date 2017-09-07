#!/bin/bash

EXECDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

usage()
{
	echo "usage: $0 -n branchName -i inputFile -d subversionBaseDirectory -b -r"
	echo "branch name is required even if you are skipping branching because"
	echo "it informs the script where the branch to be released is located."
	echo "-b do not perform branching operation (optional)"
	echo "-r do not perform release operation (optional)"
	echo "The inputFile simply contains a new line seperated list of projects."
	echo "Note: DO NOT INCLUDE PARENT."
	echo "For example:"
	echo "testing"
	echo "common"
	echo "The inputFile parameter is optional if you place a file called"
	echo "projectlist in the same directory as this script."
	echo "The subversionBaseDirectory is a valid subversion base directory that contains"
	echo "the projects that you wish to branch. This argument is optional if"
	echo "you set the SVN_BASEDIR environment variable to a valid directory."

	exit 1
}

while getopts ":n:i:d:br" opt; do
    case $opt in
    	n)
			BRANCHNAME=${OPTARG}
			;;
        i)
            PROJECTLISTFILE=${OPTARG}
            ;;
        d)
            BASEDIR=${OPTARG}
            ;;
        b)
            SKIPBRANCHING=true
            ;;
        r)
            SKIPRELEASE=true
            ;;
        *)
            usage
            ;;
        \?)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

malformedDirectory()
{
	echo "Please provide a valid subversion base directory that contains a new"
	echo "the projects that you wish to branch. This argument is optional if"
	echo "you set the SVN_BASEDIR environment variable to a valid directory."	

	exit 1
}

noProjectListFile()
{
	echo "Please provide a valid projectlist file that contains a line"
	echo "seperated list of projects. You can provide this either as an"
	echo "argument -i inputFile or place a file called projectlist in the"
	echo "same directory as this script."

	exit 1
}

if [ -z "$BRANCHNAME" ]; then
  echo "Branch Name is required"
  usage
fi

pushd ${BASEDIR:="$SVN_BASEDIR"}

if [ ! -d "$BASEDIR" ]
then
	malformedDirectory
fi

if [ ! -f "$PROJECTLISTFILE" ]
then
	PROJECTLISTFILE="$EXECDIR/projectlist"
fi

#Still not a valid file, exit.
if [ ! -f "$PROJECTLISTFILE" ]
then
	noProjectListFile
fi

IFS=$'\n' read -d '' -r -a projects < $PROJECTLISTFILE
branchProjects()
{
	project=$1
	pushd "$BASEDIR/$project/trunk"
    mvn versions:update-parent -DallowSnapshots=false -DgenerateBackupPoms=false
    mvn scm:checkin -Dincludes=pom.xml -Dmessage="maven release process automated pom checkin."
    mvn release:branch -DbranchName="$BRANCHNAME"
    popd
}

releaseProjects()
{
	project=$1
	pushd "$BASEDIR/$project/trunk"
	mvn scm:update -DworkingDirectory="$BASEDIR/$project/branches"
	popd
	pushd "$BASEDIR/$project/branches/$BRANCHNAME"
	echo "Releasing $project."
    mvn release:prepare
    mvn release:perform
    popd
}

if [[ $SKIPBRANCHING ]]; then
	echo "SKIP BRANCHING is set. Will not perform branching operation."
else
	for project in ${projects[@]}; do
		branchProjects $project
	done
fi

if [[ $SKIPRELEASE ]]; then
	echo "SKIP RELEASE is set. Will not perform release operation."
else
	for project in ${projects[@]}; do
		releaseProjects $project
	done
fi


popd
exit 0
