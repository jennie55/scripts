#!/bin/sh
# $URL: https://svn.networkfleet.com/repos/ted3/tools/trunk/genrevlog.sh $
# $Id: genrevlog.sh 12735 2012-08-09 20:17:58Z bjohnson $
#
# Generates a list of SVN log entries given two revisions.  Useful for build notice e-mails.



usage()
{
    echo -e "usage: $0 <start-rev> <end-rev>, or --from-branch <branch>"
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

projects=(
allstate-ws
api-client
api-common-parent
api-grinder-test
api-management
api-model
api-server
api-test
arch
arch-webservices
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
eda-admin
eda-common
eda-console-webapp
eda-jjk
eda-message-processor
eda-report-preprocessor
eda-tax
eda-dataservice
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
rungps-cmd
ssp-web
testing
web
)

#	cache-server common dataservice jjkeller eda-alertengine eda-common eda-console-webapp eda-message-processor media model web allstate-ws restdocs-parent api-common-parent api-model api-server api-client api-management ssp-web testing dataconnect rungps oauth2-parent

BRANCH="xxx"
EXITCODE=0
START=
END=

if [ "$1" = "--from-branch" ]; then
   if [ -z "$2" ] ; then
      warning "Required branch name. ie. REL_3.44"
   else
     # Get current rev
     BRANCH=$2
     CHECKOUT=checkout.txt
     svn checkout https://svn.networkfleet.com/repos/ted3/parent/branches/$BRANCH parent
     START=$(cat parent/pom.xml | grep "<nwf.version>" | tail -1  | sed 's/<nwf.version>\([\.0-9]*\)<\/nwf.version>/\1/' | cut -d '.' -f 4)
     END=$(svn update parent | tail -1 |  sed 's/At revision \(.*\)./\1/')

     rm -fr parent
     rm -fr $CHECKOUT
   fi

else
   if [ $# -ne 2 ]; then
       # exactly two arguments must be supplied
       warning "Exactly two arguments must be supplied"
   fi
   START=$1
   END=$2
fi

if [ $EXITCODE -gt 0 ]; then
    usage_and_exit $EXITCODE
fi


echo "From revision $START to $END"


for repo in "${projects[@]}"
do
    echo $repo:
    svn log https://svn.networkfleet.com/repos/ted3/$repo/branches/$BRANCH -r${START}:${END}

    if [ $? -ne 0 ]; then
        warning "svn log failed for $repo"
    fi
done

exit $EXITCODE
