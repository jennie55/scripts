#!/bin/sh
# $URL: https://svn.networkfleet.com/repos/ted3/tools/trunk/replaceBranch.sh $
# $Id: replaceBranch.sh 13207 2012-09-05 07:04:52Z bjohnson $

usage()
{
        echo "usage: $0 rev from toDestination"
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
api-management-env
api-model
api-server
api-server-env
api-test
arch
arch-env
arch-model
cache-server
common
dataconnect
dataconnect-common
dataconnect-env
dataservice
dataservice-env
eda-alertengine
eda-common
eda-console-webapp
eda-jjk
eda-jjk-env
eda-message-processor
eda-tax
eda-tax-env
jjkeller
jjkeller-env
legacygateway
media
model
nwffaces
nwffaces-all
oauth2-authorization-server-env
oauth2-parent
parent
restdocs-parent
rungps
rungps-web
ssp-env
ssp-web
testing
web
)

DEVUSER=`logname`

if [ $# -ne 3 ]; then
        # exactly two arguments must be supplied
        warning "Exactly three arguments must be supplied. Example: replaceBranch.sh 1234 branches/project branches/prod"
fi

REV=$1
TAG=$2
DEST=$3

if [[ ! "$REV" =~ ^[[:digit:]]+$ ]]; then
        warning "Invalid revision \"${REV}\".  Must be all numeric."
fi

if [ ${DEST} = "trunk" ]; then
    warning "Invalid destination. ${DEST} is invalid."
fi

if [ $EXITCODE -gt 0 ]; then
        usage_and_exit $EXITCODE
fi

echo -n "Checking validity of revision."

for P in ${PROJECTS[@]}; do
        echo -n "."
        svn info https://svn.networkfleet.com/repos/ted3/${P}@${REV} 1>/dev/null 2>svninfo.out
        if [ $? -ne 0 ]; then
                warning "\nInvalid revision (${REV}) for project ${P}"
                cat svninfo.out
                exit $EXITCODE
        fi
        echo -n "."
        svn info https://svn.networkfleet.com/repos/ted3/${P}/${TAG} 1>/dev/null 2>&1
        if [ $? -ne 0 ]; then
            warning "\nReplace from ${TAG} does not exist for project ${P}"
                exit $EXITCODE
        fi
        echo -n "."
        svn info https://svn.networkfleet.com/repos/ted3/${P}/${DEST} 1>/dev/null 2>&1
        if [ $? -ne 0 ]; then
            warning "\nDestination ${DEST} does not exist for project ${P}"
            exit $EXITCODE
        fi
done
echo "."
rm svninfo.out

for P in ${PROJECTS[@]}; do
        CMD="svn rm https://svn.networkfleet.com/repos/ted3/${P}/${DEST} -m\"${DEVUSER} removing the ${DEST} branch\""
        CMD2="svn copy https://svn.networkfleet.com/repos/ted3/${P}/${TAG}@${REV} https://svn.networkfleet.com/repos/ted3/${P}/${DEST} -m\"${DEVUSER} creating ${DEST} branch from ${TAG}\""
        # -e is Linux echo flag to enable interpretation of backslash escapes
        echo -e $CMD
        eval $CMD
        SVNRMEX=$?
        if [ $SVNRMEX -ne 0 ]; then
                warning "Something went wrong with svn del command. Bailing!"
                exit $SVNRMEX
        else
                echo -e $CMD2
                eval $CMD2
                SVNCPEX=$?
                if [ $SVNCPEX -ne 0 ]; then
                        warning "Something went wrong with svn cp command. Bailing!"
                        exit $SVNMVEX
                fi
        fi
done

echo "All project successfully replaced."

exit 0
