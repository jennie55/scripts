#!/bin/bash
set -e

# This is particular to the Teamcity host
export JAVA_HOME=/usr/java/jdk1.7.0_79
export M2_HOME=/usr/local/teamcity-data/apache-maven-3.1.1
export PATH=$PATH:$M2_HOME/bin
export MAVEN_OPTS=-XX:MaxPermSize=512m

#
SVN_HOME='.'

source  /usr/local/teamcity-data/automation/tools/projects_R11.list

function checkout(){
	svn checkout --quiet https://svn.networkfleet.com/repos/ted3 ted3 --depth empty
        
	CHECKOUT_BRANCH=$1

	svn status *
	for project in "${PROJECTS[@]}"
	do
		echo "Checking out $project..."
		svn update --quiet ted3/$project --depth empty
		svn update --quiet ted3/$project/branches --depth empty
		svn update --quiet ted3/$project/${CHECKOUT_BRANCH} --depth infinity
	done
}

function revert(){

	# from $SVN_HOME issue recursive revert
	svn revert -R *
}

function bump() {

    original=( "$1" )
	version=( "$2" )

    # check if original is missing
	[[ ! "$original" || ! "$version" ]] && echo "bump requires two versions arguments" && exit 1

	# search tree for pom.xml files that contain "original" snapshot text
	poms=( $(egrep -lir --include=pom.xml "${original}" .) )

	# within each pom.xml replace string $original with $version
	for pom in "${poms[@]}"
	do
		echo "Updating $pom $original -> $version"
		sed -i "s|$original|$version|g" $pom
	done

	# display svn status
	#svn status -u *

}

function status(){
    rm -f targets.txt

	svn status * | sed 's/^. *//g' | tee status.txt 

    while read L
    do
      # "Is $L a path?"

      if [ -e "$L" ] ; then
          F=$(basename $L)
          if [ "$F" == "pom.xml" ] ; then
             echo $L >> targets.txt
          fi
      fi
    done < status.txt 

    rm -f status.txt 
    # check that all lines are file names under the ./ted3 path
}



function genrevlog(){
    START=$1
    END=$2
    BRANCH=$3
    LOGOUT=$4
    rm -f $LOGOUT

    echo "From revision $START to $END. " >> $LOGOUT
    echo -e "\n\n" >> $LOGOUT
    for repo in "${PROJECTS[@]}"
    do
       echo $repo:  >> $LOGOUT
       svn log https://svn.networkfleet.com/repos/ted3/$repo/$BRANCH -r${START}:${END} >> $LOGOUT

       if [ $? -ne 0 ]; then
           warning "svn log failed for $repo"
       fi
    done

}


# **********************************************************************************************************
# main
# **********************************************************************************************************

BRANCH_SVN=$1
REV_LOG=$2

if [ -z $BRANCH_SVN ] ; then

	echo "A parameter is required (i.e. branches/REL_3.44)"
        exit 1
fi


# create $SVN_HOME if necessary
[[ -d $SVN_HOME ]] || mkdir $SVN_HOME

pushd $SVN_HOME > /dev/null

# Get rid of previous task
rm -fr ./ted3

# Get current rev
CHECKOUT=checkout.txt
svn checkout https://svn.networkfleet.com/repos/ted3/parent/$BRANCH_SVN parent > $CHECKOUT
REVISION=$(tail -n 1 $CHECKOUT | cut -d ' ' -f 4 | cut -d '.' -f 1 )
FROM_REV=$(grep "<nwf.version>"  parent/pom.xml  | cut -d '>' -f 2 | cut -d '<' -f 1)
TO_REV=$(echo $FROM_REV | cut -b 1-8).${REVISION}
echo $FROM_REV / $REVISION / $TO_REV
rm -fr parent
rm $CHECKOUT

if [ -n "$REV_LOG" ] ; then
    PREV_REV=$(echo $FROM_REV  | grep -oE "[^.]+$")
    echo "genrevlog $REV_LOG $PREV_REV $REVISION"
    genrevlog  $PREV_REV $REVISION $BRANCH_SVN $REV_LOG
fi

# 
# checkout all source (this is dumb)
checkout $BRANCH_SVN
# change string (this is dumber, but mvn version plugin can't figure out our poms.
bump $FROM_REV $TO_REV
# create list of modified pom files, puts it in targets.txt
status

COMMAND="svn commit --targets targets.txt -m'Creating version $TO_REV'"
echo $COMMAND
svn commit --targets targets.txt -m "Creating version $TO_REV from $FROM_REV"

popd > /dev/null

echo "Done."

