#!/bin/sh
# $URL: https://svn.networkfleet.com/repos/ted3/tools/trunk/tagprod.sh $
# $Id: tagprod.sh 13207 2012-09-05 07:04:52Z bjohnson $
#
# Tag prod branch of all projects for release

usage()
{
        echo "usage: $0 rev tag targetBranch"
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
PROJECTS=( 
allstate-ws
api-client
api-common-parent
api-grinder-test
api-management
api-model
api-server
api-test
arch
arch-dataservice
arch-webservice
arch-model
cache-server
common
dataconnect
dataconnect-common
dataservice
dataservice-base
dms-dataservice
eda-alertengine
eda-common
eda-console-webapp
eda-jjk
eda-message-processor
eda-report-preprocessor
eda-tax
#eda-dataservice
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
ssp-web
testing
web
)

DEVUSER=`logname`

if [ $# -ne 3 ]; then
        warning "Exactly three arguments must be supplied"
fi

REV=$1
TAG=$2
TARGET_BRANCH=$3

if [[ ! "$REV" =~ ^[[:digit:]]+$ ]]; then
        warning "Invalid revision \"${REV}\".  Must be all numeric."
fi

if [[ ! "$TAG" =~ ^rel3\.[[:digit:]]+\.[[:digit:]]+$ ]]; then
        warning "Invalid tag \"${TAG}\".  Format must match: rel3.XX.X"
fi

if [ $EXITCODE -gt 0 ]; then
        usage_and_exit $EXITCODE
fi

echo -n "Checking validity of revision and tag."

for P in ${PROJECTS[@]}; do
        echo -n "."
        svn info https://svn.networkfleet.com/repos/ted3/${P}@${REV} 1>/dev/null 2>svninfo.out
        if [ $? -ne 0 ]; then
                warning "\nInvalid revision (${REV}) for project ${P}"
                cat svninfo.out
                exit $EXITCODE
        fi
        echo -n "."
        svn info https://svn.networkfleet.com/repos/ted3/${P}/tags/${TAG} 1>/dev/null 2>&1
        # we *want* an error here
        if [ $? -eq 0 ]; then
                warning "\nTag ${TAG} already exists for project ${P}"
                exit $EXITCODE
        fi
done
echo "."
rm svninfo.out

for P in ${PROJECTS[@]}; do
        CMD="svn copy https://svn.networkfleet.com/repos/ted3/${P}/branches/${TARGET_BRANCH}@${REV} https://svn.networkfleet.com/repos/ted3/${P}/tags/${TAG} -m\"${DEVUSER} tagging ${TARGET_BRANCH} branch for ${TAG} release\""
        # -e is Linux echo flag to enable interpretation of backslash escapes
        echo -e $CMD
        eval $CMD
        SVNCPEX=$?
        if [ $SVNCPEX -ne 0 ]; then
                warning "Something went wrong with svn cp command. Bailing!"
                exit $SVNCPEX
        fi
done

echo "All project successfully tagged."

exit 0
