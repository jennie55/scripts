#!/bin/sh
# $URL: https://svn.networkfleet.com/repos/ted3/tools/trunk/tagstart.sh $
# $Id: tagstart.sh 13207 2012-09-05 07:04:52Z bjohnson $

usage()
{
        echo "usage: $0 rev tag"
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
PROJECTS=( common model dataservice jjkeller eda-alertengine eda-common eda-console-webapp eda-message-processor media cache-server restdocs-parent api-common-parent api-model api-server api-client api-management dataconnectclient legacygateway rungps  web)
DEVUSER=`logname`

if [ $# -ne 2 ]; then
        # exactly two arguments must be supplied
        warning "Exactly two arguments must be supplied"
fi

REV=$1
TAG=$2

if [[ ! "$REV" =~ ^[[:digit:]]+$ ]]; then
        warning "Invalid revision \"${REV}\".  Must be all numeric."
fi

if [[ ! "$TAG" =~ ^start3\.[[:digit:]]+\.[[:digit:]]+$ ]]; then
        warning "Invalid tag \"${TAG}\".  Format must match: rel3.XX.XX"
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
        CMD="svn copy https://svn.networkfleet.com/repos/ted3/${P}/branches/prod@${REV} https://svn.networkfleet.com/repos/ted3/${P}/tags/${TAG} -m\"${DEVUSER} tagging prod branch for the start of ${TAG} \""
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
