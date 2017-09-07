#!/bin/sh
# $URL: https://svn.networkfleet.com/repos/ted3/tools/trunk/genrevlog.sh $
#
# Generates a list of SVN log entries given two revisions.  Useful for build notice e-mails.



usage()
{
    echo -e "usage: $0  --from-branch <branch>"
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


usage_exit()
{
    exit $1
}


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
EXITCODE=0
BRANCH=$1
TED25_PATH=$2

if [ -z "$BRANCH" ] || [ -z "$TED25_PATH" ]; then
    warning "Required branch name and path.  REL_3.44 /tmp/ted25 "
    exit 2
else
    IS_TRUNK=$(echo $BRANCH | grep -i "Trunk")
    IS_DEV =$(echo $BRANCH | grep -i "Dev")

    if [ -z "$IS_TRUNK" ] ; then
       # Get current rev
       svn --quiet checkout https://svn.networkfleet.com/repos/ted3/parent/branches/$BRANCH parent
       REVISION=$(cat parent/pom.xml | grep "<nwf.version>" | tail -1  | sed 's/\(\s*\)<nwf.version>\([\.0-9]*\)<\/nwf.version>/\2/')
       rm -fr parent
       STATIC="PROD"
    elif [ -z "$IS_DEV" ] ; then
        REVISION="NIGHTLY-SNAPSHOT"
        STATIC="DEV"
    else
       REVISION="NIGHTLY-SNAPSHOT"
       STATIC="TEST"
    fi
fi

if [ $EXITCODE -gt 0 ]; then
    usage_and_exit $EXITCODE
fi

echo "From revision '$REVISION'"
echo "Using path $TED25_PATH"

# This scripts runs as teamcity. No default mvn installation for the user, so we have to explicitly tell where maven lives.
source ~/m2.sh

# the actual copy
FILES=( webservices.war NetworkCar.ear ../static.pub.${STATIC}.zip )
REAL_FILES=( webservices NetworkCar ../static.pub )
PACKAGING=( war ear zip )
ARTIFACT_ID=( webservices networkcar static )

IDX=0
for FILE in ${FILES[@]}
do
    echo $TED25_PATH/$FILE
    echo ${ARTIFACT_ID[$IDX]}
    echo ${PACKAGING[$IDX]}
    echo $REVISION

    RENAMED=${REAL_FILES[$IDX]}-${STATIC}.${PACKAGING[${IDX}]}
    echo "--> ${RENAMED}"
    cp $FILE  $RENAMED

    #mvn deploy:deploy-file -DgroupId=com.networkfleet.ted25 -DartifactId=${ARTIFACT_ID[$IDX]} -Dversion=$REVISION -DgeneratePom=true -Dpackaging=${PACKAGING[$IDX]}  -DrepositoryId=nexus -Durl=http://localhost:8081/nexus/content/repositories/releases -Dfile=$TED25_PATH/$RENAMED

    let IDX=$IDX+1
done

exit 0

