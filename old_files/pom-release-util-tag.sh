#!/bin/bash
set -e

ARGS=( "$@" )


SVN_HOME='.'

declare -a projects=(

#'allstate-ws'
#'api-client'
#'api-common-parent'
#'api-grinder-test'
#'api-management'
#'api-model'
#'api-server'
#'api-test'
#'arch'
#'arch-dataservice'
#'arch-model'
#'cache-server'
#'common'
#'dataconnect'
#'dataconnect-common'
#'dataservice'
#'dms-dataservice'
#'eda-alertengine'
#'eda-common'
#'eda-console-webapp'
#'eda-jjk'
#'eda-message-processor'
#'eda-tax'
#'jjkeller'
#'legacygateway'
#'media'
#'model'
#'nwffaces'
#'nwffaces-all'
#'oauth2-parent'
#'parent'
#'restdocs-parent'
#'rungps'
#'rungps-web'
'ssp-web'
#'testing'
#'web'
)

function checkout(){
	svn checkout https://svn.networkfleet.com/repos/ted3 ted3 --depth empty
        
	CHECKOUT_BRANCH=$1

	svn status *
	for project in "${projects[@]}"
	do
		echo "Checking out $project..."
		svn update ted3/$project --depth empty
		svn update ted3/$project/tags --depth empty
		svn update ted3/$project/${CHECKOUT_BRANCH} --depth infinity
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
	svn status * | sed 's/^. *//g' | tee targets.txt
}

# create $SVN_HOME if necessary
[[ -d $SVN_HOME ]] || mkdir $SVN_HOME

pushd $SVN_HOME > /dev/null

case "${ARGS[0]}" in
  checkout)          checkout  "${ARGS[1]}";;
    revert)          revert;;
      bump)          bump "${ARGS[1]}" "${ARGS[2]}";;
    status)          status;;
         *) echo "Usage: $0 [checkout|revert|bump]" && exit 1
esac

popd > /dev/null
