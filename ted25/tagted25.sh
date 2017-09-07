#!/bin/sh
# $URL: https://svn.networkfleet.com/repos/ted3/tools/trunk/ted25/tagted25.sh $
# $Id: tagprod.sh 13207 2012-09-05 07:04:52Z bjohnson $
#
# Create a tag of ted25 trunk
#
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


DEVUSER=`logname`

if [ $# -ne 2 ]; then
        warning "Exactly two arguments must be supplied"
fi

REV=$1
TAG=$2

if [[ ! "$REV" =~ ^[[:digit:]]+$ ]]; then
        warning "Invalid revision \"${REV}\".  Must be all numeric."
fi

if [[ ! "$TAG" =~ ^rel[[:digit:]]+$ ]]; then
        warning "Invalid tag \"${TAG}\".  Format must match: relXXX"
fi

if [ $EXITCODE -gt 0 ]; then
        usage_and_exit $EXITCODE
fi

echo -n "Checking validity of revision and tag."

svn info https://svn.networkfleet.com/repos/ted25legacy/trunk/ted2@${REV} 1>/dev/null 2>svninfo.out
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

echo "."
rm svninfo.out

CMD="svn copy https://svn.networkfleet.com/repos/ted25legacy/trunk/ted2@${REV} https://svn.networkfleet.com/repos/ted25legacy/tags/${TAG}_${REV} -m\"${DEVUSER} tagging ted25 for ${TAG} release\""
# -e is Linux echo flag to enable interpretation of backslash escapes
echo -e $CMD
eval $CMD
SVNCPEX=$?
if [ $SVNCPEX -ne 0 ]; then
    warning "Something went wrong with svn cp command. Bailing!"
    exit $SVNCPEX
fi

echo "Project successfully tagged."

exit 0
