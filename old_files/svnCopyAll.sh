#!/bin/sh
# $URL: https://svn.networkfleet.com/repos/ted3/tools/trunk/replaceBranch.sh $
# $Id: replaceBranch.sh 13207 2012-09-05 07:04:52Z bjohnson $

usage()
{
        echo "Usage: $0 rev fromOrigin toDestination"
	echo "Example: $0 1234 trunk branches/prod"
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

source projects_3.46.list

#PROJECTS=(
#allstate-ws
#allstate-ws-build-modules
#api-client
#api-common-parent
#api-grinder-test
#api-management
#api-management-build-modules
#api-model
#api-server
#api-server-build-modules
#api-test
#arch
#arch-build-modules
#arch-dataservice
#arch-model
#arch-webservices
#arch-webservices-client
#cache-server
#common
#config-deployment
#dataconnect
#dataconnect-build-modules
#dataconnectclient
#dataconnect-common
#dataservice
#dataservice-base
#dms-dataservice
#eda-admin
#eda-alertengine
#eda-alertengine-build-modules
#eda-common
#eda-console-webapp
#eda-console-webapp-build-modules
#eda-dataservice
#eda-jjk
#eda-jjk-build-modules
#eda-message-processor
#eda-message-processor-build-modules
#eda-report-preprocessor
#eda-report-preprocessor-build-modules
#eda-tax
#eda-tax-build-modules
#jjkeller
#legacygateway
#media
#model
#nwf-berkeleydb
#nwffaces-all
#nwf-wlstools-maven-plugin
#oauth2-build-modules
#oauth2-parent
#parent
#report
#restdocs-parent
#rungps
#rungps-cmd
#rungps-web
#ssp-web
#testing
#web
#web-build-modules
#)



DEVUSER=`logname`

if [ $# -ne 3 ]; then
        warning "Exactly three arguments must be supplied."
	usage_and_exit
fi

REV=$1
ORIG=$2
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
        svn info https://svn.networkfleet.com/repos/ted3/${P}/${ORIG} 1>/dev/null 2>&1
        if [ $? -ne 0 ]; then
            warning "\nReplace from ${ORIG} does not exist for project ${P}"
                exit $EXITCODE
        fi
done
echo "."


rm svninfo.out

for P in ${PROJECTS[@]}; do
        CMD="svn copy https://svn.networkfleet.com/repos/ted3/${P}/${ORIG}@${REV} https://svn.networkfleet.com/repos/ted3/${P}/${DEST} -m\"${DEVUSER} creating ${DEST} from ${ORIG}\""
        # -e is Linux echo flag to enable interpretation of backslash escapes
        echo -e $CMD
        eval $CMD
        SVNCPEX=$?
        if [ $SVNCPEX -ne 0 ]; then
                warning "Something went wrong with svn copy command. Bailing!"
                exit $SVNCPEX
        fi
done

echo "All projects successfully copied."

exit 0
