#!/bin/bash

TAG_NAME=$1
COMMENTS=$2

usage()
{
    echo "Creates a shell script to delete a tag. It is the first on a two step procedure to remove tags from svn."
    echo "The tag name needs to be supplied as the first parameter."
    echo "A comment sourrounded by double quotes is the second parameter."
}


usage_and_exit()
{
    usage
    exit $1
}

# https://svn.networkfleet.com/repos/ted3/api-client/tags/rel3.38.01
if [ $# -ne 2 ]; then
    usage_and_exit 3
fi

rm -f delete-tag-${TAG_NAME}.sh
echo "!#/bin/bash" > delete-tag-${TAG_NAME}.sh

svn ls https://svn.networkfleet.com/repos/ted3 > /tmp/projects
while read projname
do
   found=$( svn ls https://svn.networkfleet.com/repos/ted3/${projname}/tags 2>/dev/null | grep ${TAG_NAME} | cut -d '/' -f 1 )

   if [ "$found" == "$TAG_NAME" ] ; then
      #echo $projname | cut -d '/' -f 1
      CMDX="svn delete https://svn.networkfleet.com/repos/ted3/${projname}tags/${TAG_NAME} -m \"Deleting tag. ${COMMENTS}\""
      echo $CMDX 
      echo $CMDX >> delete-tag-${TAG_NAME}.sh
   fi

done  < /tmp/projects

rm /tmp/projects

chmod +x delete-tag-${TAG_NAME}.sh

