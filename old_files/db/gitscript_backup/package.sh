#!/bin/bash
# RB - 6/3/16 - Collect delta of DBDev file changes for deployment

# To collect all changes on a release branch, first checkout the branch
# then set BOTTOM_REV=develop, and TOP_REV=HEAD 

TOP_REV=HEAD
BOTTOM_REV=develop
BRANCH=REL_9.99

TEMPDIR=tmp
OUTPUTDIR=output
MODULES=(1_OLTP 2_DW 3_Scoop 4_DevSupport 5_ERD)

SAVEIFS=$IFS; IFS=$(echo -en "\n\b")
rm -rf $TEMPDIR; mkdir $TEMPDIR 
rm -rf $OUTPUTDIR; mkdir $OUTPUTDIR 

echo "========================================================================"
echo "*Identifying changed files*"

for directory in ${MODULES[@]}
do
  git log --name-status $BOTTOM_REV..$TOP_REV | grep $directory >> $OUTPUTDIR/changelog
done

while read LINE
do 
   FILENAME=`echo $LINE | awk '{print $2}'`
   if [ -a $FILENAME ]; then 
     echo $FILENAME
     rsync -R $FILENAME ./$TEMPDIR
   fi
done < $OUTPUTDIR/changelog

echo "========================================================================"
echo "*Concatenating SQL files*"

CONCAT_FILE=cat.sql
FILE_LIST=$OUTPUTDIR/files.txt
find ./$TEMPDIR -type f | sort > $FILE_LIST

while read LINE
do
    echo $LINE
    DIR=$(dirname $LINE)
    NEWCONCAT=`echo "$BRANCH/$DIR/$CONCAT_FILE" | sed 's/.\/tmp\///g' | sed 's/\//-/g'`
    echo -e "--CONCAT From $LINE\n" >> $OUTPUTDIR/$NEWCONCAT
    echo -e "prompt *** Starting script file $LINE\n"  >> $OUTPUTDIR/$NEWCONCAT
    cat $LINE >> $OUTPUTDIR/$NEWCONCAT
    echo -e "\n" >>  $OUTPUTDIR/$NEWCONCAT
    echo -e "prompt *** End script file $LINE\n"  >> $OUTPUTDIR/$NEWCONCAT
done < $FILE_LIST

echo "========================================================================"
echo "*Concatenated files*"
ls -1 $OUTPUTDIR/*cat.sql 

for catfile in `ls -1 $OUTPUTDIR/*cat.sql`
do
    echo -e "prompt *** Starting execution of deployment script $catfile\n$(cat $catfile)" > $catfile
    echo -e "prompt *** Completed execution of deployment script $catfile\n"  >> $catfile
done

echo "========================================================================"

IFS=$(echo -en "\n\b")
echo "Done"
