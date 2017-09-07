#!/bin/bash

DIRS=(1_OLTP 2_DW 3_Scoop 4_DevSupport 5_ERD UNIX)
COMP_DIR=./comp


mkdir $COMP_DIR

BRANCH=$1

if [ -z "$BRANCH" ] ; then
    echo "Parameter required: branch name (e.g.: branches/REL_3.45)"
    exit 2
fi

# For each top level
cd $COMP_DIR
for P in ${DIRS[@]}
do
        echo $P
        svn --quiet checkout https://svn.networkfleet.com/repos/ted3/nwf_db/$P/$BRANCH $P
done
cd ..

while read line
do
    OBJECT=$(echo $line | cut -d ',' -f 1)
    echo "Looking for $OBJECT"

    x=$(grep $OBJECT `find $COMP_DIR -name 'master-concat.txt'`)
    if [ $? -gt 0 ] ; then
        echo -e "\tNot found"
    else
        echo -e "\tFound at $x"
    fi
done < toad.csv

